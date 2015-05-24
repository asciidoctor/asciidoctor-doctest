require 'asciidoctor/doctest/asciidoc_converter'
require 'asciidoctor/doctest/generator'
require 'asciidoctor/doctest/test_reporter'
require 'asciidoctor/doctest/tester'
require 'asciidoctor/doctest/io/asciidoc'
require 'corefines'
require 'rake/tasklib'

using Corefines::String[:to_b, :unindent]

module Asciidoctor
  module DocTest
    ##
    # Rake tasks for testing and generating output examples.
    class RakeTasks < Rake::TaskLib

      # Genetates a description of a given task when
      # {#test_description} is not set.
      DEFAULT_TEST_DESC = ->(task) do
        <<-EOS.unindent
          Run integration tests for the #{task.subject}.

          Options (env. variables):
            PATTERN   glob pattern to select examples to test. [default: #{task.pattern}]
                      E.g. *:*, block_toc:basic, block*:*, *list:with*, ...
            VERBOSE   prints out more details [default: #{task.verbose? ? 'yes' : 'no'}]
        EOS
      end

      # Genetates a description of a given task when
      # {#generate_description} is not set.
      DEFAULT_GENERATE_DESC = ->(task) do
        <<-EOS.unindent
          Generate test examples for the #{task.subject}.

          Options (env. variables):
            PATTERN   glob pattern to select examples to (re)generate. [default: #{task.pattern}]
                      E.g. *:*, block_toc:basic, block*:*, *list:with*, ...
            FORCE     overwrite existing examples (yes/no)? [default: #{task.force? ? 'yes' : 'no'}]
        EOS
      end

      private_constant :DEFAULT_TEST_DESC, :DEFAULT_GENERATE_DESC

      # @return [#to_sym] namespace for the +:test+ and +:generate+ tasks. The
      #         +:test+ task will be set as the default task of this namespace.
      attr_accessor :tasks_namespace

      # @return [#to_s, #call] description of the test task.
      attr_accessor :test_description

      # @return [#to_s, #call] description of the generator task.
      attr_accessor :generate_description

      # @return [Class, IO::Base] an instance of {IO::Base} subclass to read
      #         the reference input examples (default: +IO::Asciidoc+).
      attr_accessor :input_suite

      # @return [Hash]
      attr_accessor :input_suite_opts

      # @return [Class, IO::Base] an instance of {IO::Base} subclass to read
      #         and generate the output examples.
      attr_accessor :output_suite

      # @return [Hash]
      attr_accessor :output_suite_opts

      attr_accessor :converter

      # @return [Hash] options for the Asciidoctor converter.
      # @see AsciidocConverter#initialize
      attr_accessor :converter_opts

      # @return [String] glob pattern to select examples to test or
      #   (re)generate. May be overriden with +PATTERN+ variable on the command
      #   line (default: +\*:*+).
      attr_accessor :pattern

      # @return [Minitest::Reporter] an instance of +Reporter+ subclass to
      #   report test results.
      # @note Used only in the test task.
      attr_accessor :test_reporter

      # @return [Boolean] whether to print out more details (default: false).
      #   May be overriden with +VERBOSE+ variable on the command line.
      # @note Used only in the test task and with the default {#test_reporter}.
      attr_accessor :verbose

      # @return [Boolean] whether to rewrite an already existing testing
      #   example. May be overriden with +FORCE+ variable on the command line
      #   (default: false).
      # @note Used only in the generator task.
      attr_accessor :force


      ##
      # Defines and configures +:test+ and +:generate+ rake tasks under the
      # specified namespace.
      #
      # @param tasks_namespace [#to_sym] namespace for the +:test+ and
      #        +:generate+ tasks.
      # @yield [self] Gives self to the block.
      #
      def initialize(tasks_namespace = :doctest)
        @tasks_namespace = tasks_namespace
        @test_description = DEFAULT_TEST_DESC
        @generate_description = DEFAULT_GENERATE_DESC
        @input_suite = IO::Asciidoc
        @input_suite_opts = {}
        @output_suite_opts = {}
        @converter_opts = {}
        @force = false
        @pattern = '*:*'

        yield self

        fail ArgumentError, 'The output_suite must be provided!' unless @output_suite

        @input_suite = input_suite.new(input_suite_opts) if input_suite.is_a? Class
        @output_suite = output_suite.new(output_suite_opts) if output_suite.is_a? Class
        @converter = converter.new(converter_opts) if converter.is_a? Class
        @test_reporter ||= TestReporter.new($stdout, verbose: verbose?,
          title: "Running DocTest for the #{subject}.")

        namespace(tasks_namespace) do
          define_test_task!
          define_generate_task!
        end

        desc "Alias for #{tasks_namespace}:test."
        task tasks_namespace => "#{tasks_namespace}:test"
      end

      def pattern
        ENV['PATTERN'] || @pattern
      end

      # (see #force)
      def force?
        ENV.fetch('FORCE', @force.to_s).to_b
      end

      alias_method :force, :force?

      # (see #verbose)
      def verbose?
        ENV.fetch('VERBOSE', @verbose.to_s).to_b
      end

      alias_method :verbose, :verbose?

      # @private
      def subject
        {
          converter: 'converter',
          template_dirs: 'templates',
          backend_name: 'backend'
        }
        .each do |key, desc|
          val = converter_opts[key]
          return "#{desc}: #{val}" if val
        end
      end

      protected

      def run_tests!
        tester = Tester.new(input_suite, output_suite, @converter, @test_reporter)
        fail unless tester.run_tests(pattern: pattern)
      end

      ##
      # @param desc [#to_s, #call] description of the next rake task. When the
      #        given object responds to +#call+, then it's invoked with +self+
      #        as a parameter. The result is expected to be a +String+.
      def desc(desc)
        super desc.respond_to?(:call) ? desc.call(self) : desc.to_s
      end

      private

      def define_test_task!
        desc test_description
        task :test do
          run_tests!
        end
      end

      def define_generate_task!
        desc generate_description
        task :generate do
          puts "Generating test examples #{pattern} in #{output_suite.examples_path.first}"

          Generator.new(input_suite, output_suite, @converter)
                   .generate! pattern: pattern, rewrite: force?
        end
      end
    end
  end
end
