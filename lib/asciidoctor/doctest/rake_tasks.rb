# frozen_string_literal: true
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
                      E.g. *:*, toc:basic, inline*:*, *list:with*, ...
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
                      E.g. *:*, toc:basic, inline*:*, *list:with*, ...
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
        @input_examples = IO.create(:asciidoc)
        @converter_opts = {}
        @force = false
        @pattern = '*:*'

        yield self

        fail ArgumentError, 'The output_examples must be provided!' unless @output_examples

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

      ##
      # Specifies a reader for the input examples. Defaults to +:asciidoc+ with
      # the built-in reference examples.
      #
      # @overload input_examples(format, opts)
      #   @param format [Symbol, String]
      #   @param opts [Hash]
      #   @option opts :path see {#output_examples}
      #   @option opts :file_ext see {#output_examples}
      #
      # @overload input_examples(io)
      #   @param io [IO::Base]
      #
      def input_examples(*args)
        @input_examples = create_io(*args)
      end

      ##
      # Specifies a reader/writer for the output examples (required).
      #
      # @overload output_examples(format, opts)
      #   @param format [Symbol, String]
      #   @param opts [Hash]
      #   @option opts :path [String, Array<String>] path of the directory
      #           (or multiple directories) where to look for the examples.
      #           Default is {DocTest.examples_path}.
      #   @option opts :file_ext [String] the filename extension (e.g. +.adoc+)
      #           of the examples files. Default value depends on the
      #           specified format.
      #
      # @overload output_examples(io)
      #   @param io [IO::Base]
      #
      def output_examples(*args)
        @output_examples = create_io(*args)
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
        tester = Tester.new(@input_examples, @output_examples, @converter, @test_reporter)
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
          puts "Generating test examples #{pattern} in #{@output_examples.path.first}"

          Generator.new(@input_examples, @output_examples, @converter)
                   .generate! pattern: pattern, rewrite: force?
        end
      end

      def create_io(*args)
        case args.first
        when Symbol, String
          IO.create(*args)
        else
          args.first
        end
      end
    end
  end
end
