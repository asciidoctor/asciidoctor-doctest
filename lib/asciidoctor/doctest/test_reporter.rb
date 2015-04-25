# coding: utf-8
require 'minitest'

using Corefines::String[:color, :indent]

module Asciidoctor
  module DocTest
    ##
    # This class is responsible for printing a formatted output of the test run.
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
      # @param result [Minitest::Test] a single test result.
      # @note Overrides method from +Minitest::StatisticsReporter+.
      def record(result)
        result.extend ResultExt

        if verbose?
          io.puts [ result.symbol.color(result.color), result.name ].join('  ')
        else
          io.print result.result_code.color(result.color)
        end

        super
      end

      ##
      # Outputs the summary of the run.
      # @note Overrides method from +Minitest::StatisticsReporter+.
      def report
        super
        io.puts unless verbose? # finish the dots
        io.puts ['', aggregated_results, summary, ''].compact.join("\n")
      end

      # @private
      def aggregated_results
        filtered_results = verbose? ? results : results.reject(&:skipped?)

        return nil if filtered_results.empty?

        str = "Aggregated results:\n"
        filtered_results.each do |res|
          str << "\n#{res.symbol}  #{res.failure.result_label}: ".color(res.color)
          str << "#{res.name}\n#{res.failure.message.indent(3)}\n\n"
        end

        str
      end

      # @private
      def summary
        str = "#{count} examples ("
        str << [
          ("#{passes} passed".color(:green) if passes > 0),
          ("#{failures} failed".color(:red) if failures > 0),
          ("#{errors} errored".color(:yellow) if errors > 0),
          ("#{skips} skipped".color(:cyan) if skips > 0)
        ].compact.join(', ') + ")\n\n"

        str << "Finished in %.3f s.\n" % total_time

        if results.any?(&:skipped?) && !verbose?
          str << "\nYou have skipped tests. Run with VERBOSE=yes for details.\n"
        end

        str
      end

      ##
      # @return [Fixnum] number of passed tests (examples).
      def passes
        count - failures - errors - skips
      end

      ##
      # @return [Boolean] whether verbose mode is enabled.
      def verbose?
        !!options[:verbose]
      end


      ##
      # @private
      # Module to be included into +Minitest::Test+.
      module ResultExt

        def symbol
          RESULT_SYMBOL[result_code.to_sym]
        end

        def color
          RESULT_COLOR[result_code.to_sym]
        end
      end
    end
  end
end
