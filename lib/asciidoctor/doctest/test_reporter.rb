# coding: utf-8
require 'minitest'

using Corefines::String::color

module Asciidoctor
  module DocTest
    class TestReporter < Minitest::StatisticsReporter

      RESULT_COLOR  = { :'.' => :green, E: :yellow, F: :red, S: :cyan }
      RESULT_SYMBOL = { :'.' => '✓', E: '⚠', F: '✗', S: '∅' }

      private_constant :RESULT_COLOR, :RESULT_SYMBOL

      ##
      # @note Overrides method from +Minitest::StatisticsReporter+.
      def start
        super
        io.puts "\n" + (options[:title] || 'Running DocTest:') + "\n\n"
      end

      ##
      # @note Overrides method from +Minitest::StatisticsReporter+.
      def record(result)
        color = RESULT_COLOR[result.result_code.to_sym]

        if verbose?
          symbol = RESULT_SYMBOL[result.result_code.to_sym]
          io.puts "#{symbol}  #{result.name.sub(':', ' : ')}".color(color)
        else
          io.print result.result_code.color(color)
        end

        super
      end

      ##
      # @note Overrides method from +Minitest::StatisticsReporter+.
      def report
        super
        io.puts unless verbose? # finish the dots
        io.puts ['', statistics, aggregated_results, summary].join("\n")
      end

      def statistics
        "Finished in %.6fs, %.4f runs/s, %.4f assertions/s." %
          [total_time, count / total_time, assertions / total_time]
      end

      def aggregated_results
        filtered_results = verbose? ? results : results.reject(&:skipped?)

        filtered_results.each_with_index.map { |result, i|
          "\n%3d) %s" % [i + 1, result]
        }.join("\n") + "\n"
      end

      def summary
        if results.any?(&:skipped?) && !verbose?
          extra = "\n\nYou have skipped tests. Run with VERBOSE=yes for details."
        end
        color = failures + errors > 0 ? :red : :green

        "#{count} examples, #{failures} failed, #{errors} errored, #{skips} skipped#{extra}".color(color)
      end

      def verbose?
        !!options[:verbose]
      end
    end
  end
end
