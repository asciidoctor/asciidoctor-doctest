require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/try'
require 'asciidoctor'
require 'diffy'
require 'minitest'

module Minitest
  module Diffy

    def self.included(base)
      base.make_my_diffs_pretty!
    end

    def diff(exp, act)
      expected = mu_pp_for_diff(exp)
      actual = mu_pp_for_diff(act)

      if need_diff?(expected, actual)
        ::Diffy::Diff.new(expected, actual, context: 3).to_s
            .insert(0, "\n")
            .gsub(/^\\ No newline at end of file\n/, '')
      else
        "Expected: #{mu_pp(exp)}\n  Actual: #{mu_pp(act)}"
      end
    end

    private

    def need_diff?(expected, actual)
      expected.include?("\n") ||
        actual.include?("\n") ||
        expected.size > 30    ||
        actual.size > 30      ||
        expected == actual
    end
  end
end

module Asciidoctor
  module DocTest
    ###
    # Base class for integration tests of Asciidoctor backends.
    class BaseTest < Minitest::Test
      include Minitest::Diffy

      class << self
        attr_reader :asciidoc_suite_parser, :tested_suite_parser
      end

      ##
      # Sets path of the directory (or multiple directories) where to look for
      # the backend's templates. When not specified, {DocTest.templates_path}
      # will be used. Relative paths are referenced from the working directory.
      #
      # @param path [String, Array<String>]
      #
      def self.templates_path(path)
        @templates_path = path ? Array.wrap(path) : nil
      end

      ##
      # Generates the test methods.
      #
      # @param asciidoc_suite_parser [BaseSuiteParser] instance of suite parser
      #        to be used for reading the reference AsciiDoc examples.
      #
      # @param tested_suite_parser [BaseSuiteParser] instance of suite parser
      #        to be used for reading the tested examples.
      #
      def self.generate_tests!(asciidoc_suite_parser, tested_suite_parser)
        @asciidoc_suite_parser = asciidoc_suite_parser
        @tested_suite_parser = tested_suite_parser

        suite_names.each do |suite_name|
          tested_suite = read_tested_suite(suite_name)

          read_asciidoc_suite(suite_name).each do |exmpl_name, adoc|
            test_name = "#{suite_name}:#{exmpl_name}"

            if (opts = tested_suite.try(:[], exmpl_name))
              expected = opts.delete(:content)
              asciidoc = adoc[:content]

              define_test(test_name) do
                actual = render_asciidoc(asciidoc, opts)
                assert_example expected, actual, opts
              end
            else
              define_test(test_name) do
                skip 'No example found'
              end
            end
          end
        end
      end

      ##
      # Returns names of all testing suites.
      # @return [Array<String>]
      def self.suite_names
        @asciidoc_suite_parser.suite_names
      end

      ##
      # @see BaseSuiteParser#read_suite
      def self.read_asciidoc_suite(suite_name)
        @asciidoc_suite_parser.read_suite(suite_name)
      end

      ##
      # @see BaseSuiteParser#read_suite
      def self.read_tested_suite(suite_name)
        @tested_suite_parser.read_suite(suite_name)
      end

      ##
      # Defines a new test method.
      #
      # @param name [String] name of the test (method).
      # @param block [Proc] the test method's body.
      #
      def self.define_test(name, &block)
        (@test_methods ||= []) << name
        define_method(name, block)
      end

      ##
      # @note Overrides method from +Minitest::Test+.
      # @return [Array] names of the test methods to run.
      def self.runnable_methods
        (@test_methods || []) + super
      end

      ##
      # Renders the given text in AsciiDoc syntax with Asciidoctor using the
      # tested backend, i.e. templates on {#templates_path}.
      #
      # @param text [String] the input text in Asciidoc syntax.
      # @param opts [Hash]
      # @option opts :header_footer whether to render a full document.
      # @return [String] the input text rendered in the tested syntax.
      #
      def render_asciidoc(text, opts = {})
        templates_path = self.class.instance_variable_get(:@templates_path)
        renderer_opts = {
          safe: :safe,
          template_dirs: templates_path || DocTest.templates_path,
          header_footer: opts.key?(:header_footer)
        }
        Asciidoctor.render(text, renderer_opts)
      end

      ##
      # @note Overrides method from +Minitest::Test+.
      # @return [String] the name of this test that will be printed in a report.
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
        assert_equal expected, actual
      end
    end
  end
end
