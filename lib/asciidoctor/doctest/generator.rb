require 'asciidoctor'
require 'corefines'

using Corefines::String::color

module Asciidoctor
  module DocTest
    module Generator

      ##
      # Generates missing, or rewrite existing output examples from the
      # input examples converted using the +renderer+.
      #
      # @param output_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read and generate the output
      #        examples.
      #
      # @param input_suite [BaseExamplesSuite] an instance of
      #        {BaseExamplesSuite} subclass to read the reference input
      #        examples.
      #
      # @param renderer [#convert]
      #
      # @param pattern [String] glob-like pattern to select examples to
      #        (re)generate (see {BaseExample#name_match?}).
      #
      # @param rewrite [Boolean] whether to rewrite an already existing
      #        example.
      #
      # @param log_os [#<<] output stream where to write log messages.
      #
      def self.generate!(output_suite, input_suite, renderer, pattern: '*:*',
                         rewrite: false, log_os: $stdout)
        updated = []

        input_suite.pair_with(output_suite).each do |input, output|
          next unless input.name_match? pattern

          log = ->(msg, color = :default) do
            log_os << " --> #{(msg % input.name).color(color)}\n" if log_os
          end

          if input.empty?
            log["Unknown %s, doesn't exist in input examples!"]
          else
            rendered = output_suite.convert_example(input, output.opts, renderer)
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

        output_suite.update_examples updated unless updated.empty?
      end
    end
  end
end
