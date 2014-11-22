require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/try'
require 'asciidoctor/doctest/core_ext'
require 'asciidoctor/doctest/minitest_diffy'
require 'asciidoctor/doctest/template_converter_adapter'
require 'asciidoctor'
require 'minitest'

module Asciidoctor
  module DocTest
    ##
    # Base class for testing Asciidoctor backends.
    class BaseTest < Minitest::Test
      include MinitestDiffy

      ##
      # Allow to fall back to using the appropriate built-in converter when
      # there is no required template in the tested backend.
      # This is actually a default behaviour in Asciidoctor, but since it's
      # inappropriate for testing of custom backends, it's disabled by default
      # in this test class.
      #
      def self.allow_template_fallback(allow = true)
        @templates_fallback = allow
      end

      ##
      # Defines name of the tested backend and optionally the specific
      # converter.
      #
      # @param name [#to_s] the name of the tested backend.
      # @param converter [Class, Asciidoctor::Converter::Base, nil]
      #        the backend's converter class (or its instance). If not
      #        specified, the default converter for the specified backend will
      #        be used.
      #
      def self.backend(name, converter = nil)
        @backend_name = name.to_s
        @converter = converter
      end

      ##
      # Sets path of the directory (or multiple directories) where to look for
      # the backend's templates. Relative paths are referenced from the working
      # directory.
      #
      # @param paths [String, Array<String>]
      # @raise [StandardError] if any of the given paths doesn't exist or not
      #   a directory.
      #
      def self.templates_path(*paths)
        paths.flatten!
        unless paths.all? { |path| Dir.exist? path }
          fail "Templates directory '#{path}' doesn't exist!"
        end
        @templates_path = paths unless paths.empty?
      end

      ##
      # Generates test methods for all the testing examples.
      #
      # If class is given, then it's instantiated with zero arguments.
      #
      # @param tested_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading the tested examples.
      #
      # @param asciidoc_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading the reference
      #        Asciidoctor examples.
      #
      def self.generate_tests!(tested_suite_parser, asciidoc_suite_parser = AsciidocSuiteParser)
        @tested_suite_parser = tested_suite_parser.with { is_a?(Class) ? new : self }
        @asciidoc_suite_parser = asciidoc_suite_parser.with { is_a?(Class) ? new : self }

        suite_names.each do |suite_name|
          tested_suite = read_tested_suite(suite_name)

          read_asciidoc_suite(suite_name).each do |exmpl_name, adoc|
            test_name = "#{suite_name}:#{exmpl_name}"

            if (opts = tested_suite.try(:[], exmpl_name))
              expected = opts.delete(:content)
              asciidoc = adoc[:content]
              opts[:desc] ||= adoc[:desc]

              test test_name do
                actual = render_asciidoc(asciidoc, opts)
                assert_example expected, actual, opts
              end
            else
              test test_name do
                skip 'No example found'
              end
            end
          end
        end
      end

      ##
      # Returns names of all the testing suites.
      # @return [Array<String>]
      def self.suite_names
        @asciidoc_suite_parser.suite_names
      end

      def self.read_asciidoc_suite(suite_name)
        @asciidoc_suite_parser.read_suite(suite_name)
      end

      def self.read_tested_suite(suite_name)
        @tested_suite_parser.read_suite(suite_name)
      end

      ##
      # Defines a new test method.
      #
      # @param name [String] name of the test (method).
      # @param block [Proc] the test method's body.
      #
      def self.test(name, &block)
        (@test_methods ||= []) << name
        define_method(name, block)
      end

      ##
      # @private
      # @note Overrides method from +Minitest::Test+.
      # @return [Array] names of the test methods to run.
      def self.runnable_methods
        (@test_methods || []) + super
      end

      ##
      # Renders the given +text+ in AsciiDoc syntax with Asciidoctor using the
      # tested backend.
      #
      # @param text [String] the input text in AsciiDoc syntax.
      # @param opts [Hash]
      # @option opts :header_footer whether to render a full document.
      # @return [String] the input +text+ rendered in the tested syntax.
      #
      def render_asciidoc(text, opts = {})
        renderer_opts = {
          safe: :safe,
          backend: backend_name,
          converter: converter,
          template_dirs: templates_path,
          header_footer: opts.key?(:header_footer)
        }
        Asciidoctor.render(text, renderer_opts)
      end

      ##
      # @note Overrides method from +Minitest::Test+.
      # @return [String] name of this test that will be printed in a report.
      def location
        prefix = self.class.name.split('::').last
        name = self.name.sub(':', ' : ')
        "#{prefix} :: #{name}"
      end

      ##
      # Asserts an actual rendered example against the expected from the examples
      # suite.
      #
      # @note This method may be overriden to provide a more suitable assert.
      #
      # @param expected [String] the expected output.
      # @param actual [String] the actual rendered output.
      # @param opts [Hash] options.
      # @raise [Minitest::Assertion] if the assertion fails
      #
      def assert_example(expected, actual, opts)
        assert_equal expected, actual, opts[:desc]
      end

      ##
      # @private
      # Returns the backend's converter class (or its instance).
      def converter
        conv = self.class.instance_variable_get(:@converter)
        conv ||= TemplateConverterAdapter if templates_path && !templates_fallback
        conv
      end

      # generate getters for class attributes
      [:backend_name, :templates_fallback, :templates_path].each do |name|
        define_method name do
          self.class.instance_variable_get(:"@#{name}")
        end
      end
    end
  end
end
