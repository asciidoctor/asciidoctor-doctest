# frozen_string_literal: true
require 'corefines'
require 'diffy'

using Corefines::String::color

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
        else
          "Expected: #{mu_pp(exp)}\n  Actual: #{mu_pp(act)}"
        end
      end

      ##
      # Returns +true+ if diff should be printed (using Diffy) for the given
      # content, +false+ otherwise.
      #
      # @param expected [String]
      # @param actual [String]
      #
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

module Diffy
  module Format

    ##
    # ANSI color output suitable for terminal, customized for minitest.
    def minitest
      padding = ' ' * 2
      ary = map do |line|
        case line
        when /^(---|\+\+\+|\\\\)/
          # ignore
        when /^\\\s*No newline at end of file/
          # ignore
        when /^\+/
          line.chomp.sub(/^\+/, 'A' + padding).color(:red)
        when /^-/
          line.chomp.sub(/^\-/, 'E' + padding).color(:green)
        else
          padding + line.chomp
        end
      end
      "\n" + ary.compact.join("\n")
    end
  end
end

Diffy::Diff.default_format = :minitest
