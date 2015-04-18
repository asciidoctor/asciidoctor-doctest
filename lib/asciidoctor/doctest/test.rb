require 'asciidoctor/doctest/asciidoc_renderer'
require 'asciidoctor/doctest/minitest_diffy'
require 'asciidoctor/doctest/asciidoc/examples_suite'
require 'corefines'
require 'minitest'

using Corefines::Object[:presence, :try]

module Asciidoctor
  module DocTest
    ##
    # Test class for Asciidoctor backends.
    class Test < Minitest::Test
      include MinitestDiffy

      ##
      # Generates tests for all the input/output examples.
      # When some output example is missing, it's reported as skipped test.
      #
      # @param output_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read the output examples from
      #        (i.e. an expected output).
      #
      # @param input_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read the reference input
      #        examples from.
      #
      # @param renderer [#convert]
      #
      # @param pattern [String] glob-like pattern to select examples to test
      #        (see {BaseExample#name_match?}).
      #
      def self.generate_tests!(output_suite, input_suite, renderer, pattern: '*:*')
        @output_suite = output_suite
        @input_suite  = input_suite
        @renderer = renderer

        @input_suite.pair_with(@output_suite).each do |input, output|
          next unless input.name_match? pattern
          next if input.empty?

          define_test input.name do
            if output.empty?
              skip 'No expected output found'
            else
              test_example output, input
            end
          end
        end
      end

      ##
      # @private
      # Defines a new test method.
      #
      # @param name [String] name of the test (method).
      # @param block [Proc] the test method's body.
      #
      def self.define_test(name, &block)
        (@test_methods ||= []) << name
        define_method name, block
      end

      ##
      # @private
      # @note Overrides method from +Minitest::Test+.
      # @return [Array] names of the test methods to run.
      def self.runnable_methods
        @test_methods || []
      end

      ##
      # Tests if the given reference input is matching the expected output
      # after conversion through the tested backend.
      #
      # @param output_exmpl [BaseExample] the expected output example.
      # @param input_exmpl [BaseExample] the reference input example.
      # @raise [Minitest::Assertion] if the assertion fails.
      #
      def test_example(output_exmpl, input_exmpl)
        converted_exmpl = output_suite.convert_example(input_exmpl, output_exmpl.opts, renderer)
        msg = output_exmpl.desc.presence || input_exmpl.desc

        assert_equal output_exmpl, converted_exmpl, msg
      end

      ##
      # @private
      # Returns a human-readable (formatted) version of the asserted object.
      #
      # @note Overrides method from +Minitest::Assertions+.
      #
      # @param example [#to_s]
      # @return [String]
      #
      def mu_pp(example)
        example.to_s
      end

      [:input_suite, :output_suite, :renderer].each do |name|
        define_method name do
          self.class.instance_variable_get(:"@#{name}")
        end
      end

      # Overrides method from +Minitest::Test+.
      alias_method :location, :name
    end
  end
end
