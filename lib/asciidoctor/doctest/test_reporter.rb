require 'minitest'
require 'minitest/rg'

module Asciidoctor
  module DocTest
    class TestReporter < Minitest::SummaryReporter

      def initialize(io = $stdout, options = {})
        io = Minitest::RG.new(io)
        super
      end

      def record(result)
        io.print "%s = %.2f ms = " % [result.name, result.time * 1000] if verbose?
        io.print result.result_code
        io.puts if verbose?

        super
      end

      ##
      # @note Overrides method from +Minitest::SummaryReporter+.
      def summary
        if results.any?(&:skipped?) && !verbose?
          extra = "\n\nYou have skipped tests. Run with VERBOSE=yes for details."
        end
        "#{count} examples, #{failures} failed, #{errors} errored, #{skips} skipped#{extra}"
      end

      def verbose?
        !!options[:verbose]
      end
    end
  end
end
