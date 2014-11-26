require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/blank'
require 'asciidoctor/doctest/base_suite_parser'
require 'asciidoctor/doctest/core_ext'
require 'asciidoctor/doctest/example'

module Asciidoctor
  module DocTest
    ##
    # Parser and serializer of HTML-based examples suite.
    #
    # @example Format of the example's header
    #   <!-- .example-name
    #     Any text that is not the example's name or an option and doesn't
    #     start with // is considered as a description.
    #     :option-1: value 1
    #     :option-2: value 1
    #     :option-2: value 2
    #     :boolean-option:
    #   -->
    #   <p>The example's content in <strong>HTML</strong>.</p>
    #
    #   <div class="note">The trailing new line (below this) will be removed.</div>
    #
    class HtmlSuiteParser < BaseSuiteParser

      FILE_SUFFIX = '.html'

      def parse_suite(input, suite_name)
        examples = []
        current = nil
        in_comment = false

        input.each_line do |line|
          line.chomp!
          if line =~ /^<!--\s*\.([^ \n]+)/
            name = $1.to_sym
            examples << (current = Example.new([suite_name, name]))
            in_comment = true
          elsif in_comment
            if line =~ /^\s*:([^:]+):(.*)/
              current[$1.to_sym] = $2.blank? ? true : $2.strip
            elsif !line.start_with?('//')
              desc = line.rstrip.chomp('-->').strip
              (current.desc ||= '').concat(desc, "\n") unless desc.empty?
            end
          else
            (current.content ||= '').concat(line, "\n")
          end
          in_comment &= !line.end_with?('-->')
        end

        examples
      end

      def serialize_suite(examples)
        examples.map { |exmpl|
          header = [ ".#{exmpl.local_name}", exmpl.desc ].compact

          exmpl.opts.each do |name, vals|
            Array.wrap(vals).map do |val|
              header << (val == true ? ":#{name}:" : ":#{name}: #{val}")
            end
          end
          header_str = header.one? ? (header.first + ' ') : (header.join("\n") + "\n")

          "<!-- #{header_str}-->\n#{exmpl.content.chomp}\n"
        }.join("\n")
      end
    end
  end
end
