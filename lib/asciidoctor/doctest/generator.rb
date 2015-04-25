require 'asciidoctor'
require 'corefines'

using Corefines::String::color

module Asciidoctor
  module DocTest
    class Generator

      ##
      # @param input_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read the reference input
      #        examples.
      #
      # @param output_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read and generate the output
      #        examples.
      #
      # @param converter [#convert]
      #
      # @param io [#<<] output stream where to write log messages.
      #
      def initialize(input_suite, output_suite, converter, io = $stdout)
        @input_suite = input_suite
        @output_suite = output_suite
        @converter = converter
        @io = io
      end

      ##
      # Generates missing, or rewrite existing output examples from the
      # input examples converted using the +converter+.
      #
      # @param pattern [String] glob-like pattern to select examples to
      #        (re)generate (see {BaseExample#name_match?}).
      #
      # @param rewrite [Boolean] whether to rewrite an already existing
      #        example.
      #
      def generate!(pattern: '*:*', rewrite: false)
        updated = []

        @input_suite.pair_with(@output_suite).each do |input, output|
          next unless input.name_match? pattern

          log = ->(msg, color = :default) do
            @io << " --> #{(msg % input.name).color(color)}\n" if @io
          end

          if input.empty?
            log["Unknown %s, doesn't exist in input examples!"]
          else
            rendered = @output_suite.convert_example(input, output.opts, @converter)
            rendered.desc = output.desc

            if output.empty?
              log['Generating %s', :magenta]
              updated << rendered
            elsif rendered == output
              log['Unchanged %s', :green]
            elsif rewrite
              log['Rewriting %s', :red]
              updated << rendered
            else
              log['Skipping %s', :yellow]
            end
          end
        end

        @output_suite.update_examples updated unless updated.empty?
      end
    end
  end
end
