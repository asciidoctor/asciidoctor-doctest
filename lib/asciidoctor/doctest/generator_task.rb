require 'active_support/core_ext/string/strip'
require 'asciidoctor/doctest/generator'
require 'asciidoctor/doctest/core_ext'
require 'rake/tasklib'

module Asciidoctor
  module DocTest
    ##
    # Rake task for generating output examples.
    # @see Generator
    class GeneratorTask < Rake::TaskLib

      # List of values representing +true+.
      TRUE_VALUES = %w[yes y true]

      # This attribute is used only for the default {#input_suite}.
      # @return (see DocTest.examples_path)
      attr_accessor :examples_path

      # @return [Boolean] whether to rewrite an already existing testing
      #   example. May be overriden with +FORCE+ variable on the command line
      #   (default: false).
      attr_accessor :force

      # @return [BaseExamplesSuite] an instance of {BaseExamplesSuite} subclass
      #         to read the reference input examples
      #         (default: +Asciidoc::ExamplesSuite.new(examples_path: examples_path)+).
      attr_accessor :input_suite

      # @return [BaseExamplesSuite] an instance of {BaseExamplesSuite} subclass
      #         to read and generate the output examples.
      attr_accessor :output_suite

      # @return [#to_sym] name of the task.
      attr_accessor :name

      # @return [String] glob pattern to select examples to (re)generate.
      #   May be overriden with +PATTERN+ variable on the command line
      #   (default: *:*).
      attr_accessor :pattern

      # @return [Hash] options for Asciidoctor converter.
      # @see AsciidocRenderer#initialize
      attr_accessor :converter_opts

      # @return [String] title of the task's description.
      attr_accessor :title

      # Alias for backward compatibility.
      alias_method :renderer_opts, :converter_opts


      ##
      # @param name [#to_sym] name of the task.
      # @yield The block to configure this task.
      def initialize(name)
        @name = name
        @examples_path = DocTest.examples_path
        @force = false
        @input_suite = nil
        @output_suite = nil
        @converter_opts = {}
        @pattern = '*:*'
        @title = "Generate testing examples #{pattern}#{" for #{name}" if name != :generate}."

        yield self

        fail 'The output_suite is not provided!' unless @output_suite
        if @output_suite.examples_path.first == DocTest::BUILTIN_EXAMPLES_PATH
          fail "The examples_path in output suite is invalid: #{@output_suite.examples_path}"
        end

        @input_suite ||= Asciidoc::ExamplesSuite.new(examples_path: @examples_path)
        @renderer ||= AsciidocRenderer.new(converter_opts)

        define
      end

      def pattern
        ENV['PATTERN'] || @pattern
      end

      def force?
        return TRUE_VALUES.include?(ENV['FORCE'].downcase) if ENV.key? 'FORCE'
        !!force
      end

      private

      def define
        desc description

        task name.to_sym do
          puts title
          Generator.generate! output_suite, input_suite, @renderer,
                              pattern: pattern, rewrite: force?
        end
        self
      end

      def description
        <<-EOS.strip_heredoc
          #{title}

          Options (environment variables):
            PATTERN   glob pattern to select examples to (re)generate. [default: #{@pattern}]
                      E.g. *:*, block_toc:basic, block*:*, *list:with*, ...
            FORCE     overwrite existing examples (yes/no)? [default: #{@force ? 'yes' : 'no'}]

        EOS
      end
    end
  end
end
