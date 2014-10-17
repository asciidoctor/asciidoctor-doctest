require 'asciidoctor/doctest/base_suite_parser'

module Asciidoctor
  module DocTest
    ##
    # Parser for the reference Asciidoctor examples.
    #
    # @example Syntax of the example's header
    #   // .example-name
    #   // Any text that is not the example's name or an option is currently
    #   // ignored.
    #   The example's content in *Asciidoc*.
    #
    #   NOTE: The trailing new line (below this) will be removed.
    #
    class AsciidocSuiteParser < BaseSuiteParser

      FILE_SUFFIX = '.adoc'

      def parse_suite(input)
        suite = {}
        current = {}

        input.each_line do |line|
          if line =~ %r{^//\s*\.([^ \n]+)}
            current[:content].chomp! unless current.empty?
            suite[$1.to_sym] = current = { content: '' }
          elsif line.start_with? '//'
            next  # ignore for now
          else
            current[:content] << line
          end
        end
        current[:content].chomp!

        suite
      end
    end
  end
end
