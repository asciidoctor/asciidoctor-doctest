require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/slice'
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
      # Allow to fall back to using an appropriate built-in converter when
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
      # Generates test methods for all the test examples.
      #
      # If class is given, then it's instantiated with zero arguments.
      #
      # @param output_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading the output
      #        examples (i.e. an expected output).
      #
      # @param input_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading the input
      #        AsciiDoc examples.
      #
      def self.generate_tests!(output_suite_parser, input_suite_parser = AsciidocSuiteParser)
        output_sp = output_suite_parser.with { is_a?(Class) ? new : self }
        input_sp = input_suite_parser.with { is_a?(Class) ? new : self }

        input_sp.suite_names.each do |suite_name|
          outputs = output_sp.read_suite(suite_name)
          outputs_by_name = outputs.map { |e| [e.name, e] }.to_h

          input_sp.read_suite(suite_name).each do |input|
            output = outputs_by_name[input.name]

            test input.name do
              if output
                test_example input, output
              else
                skip 'No expected output found'
              end
            end
          end
        end
      end

      ##
      # Returns names of all the examples suites to test.
      # @return [Array<String>]
      def self.suite_names
        @input_suite_parser.suite_names
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
        (@test_methods || []) + super - ['test_example']
      end

      ##
      # Renders the given +text+ in AsciiDoc syntax with Asciidoctor using the
      # tested backend.
      #
      # @param text [#to_s] the input text in AsciiDoc syntax.
      # @param opts [Hash] options to pass to Asciidoctor.
      # @return [String] rendered input +text+.
      #
      def render_asciidoc(text, opts = {})
        renderer_opts = {
          safe: :safe,
          backend: backend_name,
          converter: converter,
          template_dirs: templates_path,
        }.merge(opts)

        Asciidoctor.render(text.to_s, renderer_opts)
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
      # Tests if the given reference input is matching the expected output
      # after conversion through the tested backend.
      #
      # @note This method may be overriden to provide a more suitable assert.
      #
      # @param input_exmpl [Example] the reference input example.
      # @param output_exmpl [Example] the expected output example.
      # @raise [Minitest::Assertion] if the assertion fails
      #
      def test_example(input_exmpl, output_exmpl)
        renderer_opts = { header_footer: !!output_exmpl[:header_footer] }
        actual = render_asciidoc(input_exmpl, renderer_opts)

        assert_equal output_exmpl.to_s, actual, input_exmpl.desc || output_exmpl.desc
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
