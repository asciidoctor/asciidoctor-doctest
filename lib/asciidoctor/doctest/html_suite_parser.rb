require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/array/wrap'
require 'asciidoctor/doctest/base_suite_parser'
require 'asciidoctor/doctest/core_ext'

module Asciidoctor
  module DocTest
    ##
    # Parser and serializer for HTML-based examples.
    #
    # @example Syntax of the example's header
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

      def parse_suite(html)
        suite = {}
        current = {}
        in_comment = false

        html.each_line do |line|
          if line =~ /^<!--\s*\.([^ \n]+)/
            current[:content].chomp! unless current.empty?
            suite[$1.to_sym] = current = { content: '' }
            in_comment = !line.chomp.end_with?('-->')
          elsif in_comment
            if line =~ /^\s*:([^:]+):(.*)/
              (current[$1.to_sym] ||= []) << $2.strip
            elsif !line.start_with?('//')
              desc = line.rstrip.chomp('-->').strip
              (current[:desc] ||= '').concat(desc, "\n") unless desc.empty?
            end
            in_comment = !line.chomp.end_with?('-->')
          else
            current[:content] << line
          end
        end
        current[:content].chomp! unless current.empty?

        suite
      end

      def serialize_suite(suite_hash)
        suite_hash.map { |key, hash|
          html = hash[:content].chomp
          opts = hash.except(:content)

          if opts.empty?
            "<!-- .#{key} -->\n#{html}\n"
          else
            desc = opts.delete(:desc)
            opts_str = opts.map { |name, vals|
              Array.wrap(vals).map do |val|
                ['true', ''].include?(val.to_s) ? ":#{name}:" : ":#{name}: #{val}"
              end
            }.join("\n")

            header = [ ".#{key}", desc, opts_str ].compact.join("\n")
            "<!-- #{header}\n-->\n#{html}\n"
          end
        }.join("\n")
      end
    end
  end
end
