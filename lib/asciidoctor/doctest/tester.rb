require 'asciidoctor/doctest/minitest_diffy'
require 'asciidoctor/doctest/test_reporter'
require 'corefines'
require 'minitest'

using Corefines::Object::presence

module Asciidoctor
  module DocTest
    class Tester

      ##
      # @return [Minitest::Reporter] an instance of minitest's +Reporter+
      #   to report test results.
      attr_reader :reporter

      ##
      # @param input_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read the reference input
      #        examples from.
      #
      # @param output_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read the output examples from
      #        (i.e. an expected output).
      #
      # @param converter [#call] a callable that accepts a string content of
      #        an input example and a hash with options for the converter, and
      #        returns the converted content.
      #
      # @param reporter [Minitest::Reporter, nil] an instance of minitest's
      #        +Reporter+ to report test results. When omitted or +nil+, then
      #        {TestReporter} is used.
      #
      def initialize(input_suite, output_suite, converter, reporter = nil)
        @input_suite = input_suite
        @output_suite = output_suite
        @converter = converter
        @reporter = reporter || TestReporter.new
      end

      ##
      # Runs tests for all the input/output examples which name matches
      # the _pattern_. When some output example is missing, it's reported as
      # a skipped test.
      #
      # @param pattern [String] glob-like pattern to select examples to test
      #        (see {BaseExample#name_match?}).
      #
      def run_tests(pattern: '*:*')
        @reporter.start

        @input_suite.pair_with(@output_suite).each do |input, output|
          next if input.empty? || !input.name_match?(pattern)
          test_example input, output
        end

        @reporter.report
        @reporter.passed?
      end

      ##
      # Tests if the given reference input is matching the expected output
      # after conversion through the tested backend.
      #
      # @param input_exmpl [BaseExample] the reference input example.
      # @param output_exmpl [BaseExample] the expected output example.
      #
      def test_example(input_exmpl, output_exmpl)
        test_with_minitest input_exmpl.name do |test|
          if output_exmpl.empty?
            test.skip 'No expected output found'
          else
            converted_exmpl = @output_suite.convert_example(input_exmpl, output_exmpl.opts, @converter)
            msg = output_exmpl.desc.presence || input_exmpl.desc

            test.assert_equal output_exmpl, converted_exmpl, msg
          end
        end
      end

      protected

      ##
      # Runs the given block with Minitest as a single test.
      #
      # @param [String, Symbol] test name.
      # @yield [Minitest::Test] Gives the test context to the block.
      #
      def test_with_minitest(name, &block)
        MinitestSingleTest.test! @reporter, name, name, block
      end


      # @private
      class MinitestSingleTest < Minitest::Test
        include MinitestDiffy

        # @note Overrides method from +Minitest::Test+.
        attr_reader :location

        def self.test!(reporter, name, location, callable)
          new(reporter, name, location, callable).failures
        end

        private

        def initialize(reporter, name, location, callable)
          super name
          @reporter = reporter
          @location = location
          @callable = callable
          run
          @reporter.record(self)
        end

        # @note Overrides method from +Minitest::Test+.
        def run
          with_info_handler do
            time_it do
              capture_exceptions do
                @callable.call(self)
              end
            end
          end

          self # per contract
        end

        # @note Overrides method from +Minitest::Assertions+.
        def mu_pp(example)
          example.to_s
        end
      end
    end
  end
end
