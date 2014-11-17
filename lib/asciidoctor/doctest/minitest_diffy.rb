require 'diffy'

module Asciidoctor
  module DocTest
    ##
    # Module to be included into +Minitest::Test+ to use Diffy for diff.
    module MinitestDiffy

      # @private
      def self.included(base)
        base.make_my_diffs_pretty!
      end

      ##
      # Returns diff between +exp+ and +act+ (if needed) using Diffy.
      #
      # @note Overrides method from +Minitest::Assertions+.
      def diff(exp, act)
        expected = mu_pp_for_diff(exp)
        actual = mu_pp_for_diff(act)

        if need_diff? expected, actual
          ::Diffy::Diff.new(expected, actual, context: 3).to_s
              .insert(0, "\n")
              .gsub(/^\\ No newline at end of file\n/, '')
        else
          "Expected: #{mu_pp(exp)}\n  Actual: #{mu_pp(act)}"
        end
      end

      private

      def need_diff?(expected, actual)
        expected.include?("\n") ||
          actual.include?("\n") ||
          expected.size > 30    ||
          actual.size > 30      ||
          expected == actual
      end
    end
  end
end
