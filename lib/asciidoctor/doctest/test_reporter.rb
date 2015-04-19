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
        io.print "%s = %.2f ms = " % [result.name, result.time * 1000] if options[:verbose]
        io.print result.result_code
        io.puts if options[:verbose]

        super
      end
    end
  end
end
