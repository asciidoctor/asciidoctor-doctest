require 'minitest'

using Corefines::String::color

module Asciidoctor
  module DocTest
    class TestReporter < Minitest::SummaryReporter

      RESULT_COLOR  = { :'.' => :green, E: :yellow, F: :red, S: :cyan }

      private_constant :RESULT_COLOR

      ##
      # @note Overrides method from +Minitest::AbstractReporter+.
      def record(result)
        color = RESULT_COLOR[result.result_code.to_sym]

        if verbose?
          line = "%s = %.2f ms = %s" % [result.name, result.time * 1000, result.result_code]
          io.puts line.color(color)
        else
          io.print result.result_code.color(color)
        end

        super
      end

      ##
      # @note Overrides method from +Minitest::SummaryReporter+.
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
