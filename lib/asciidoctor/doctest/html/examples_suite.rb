require 'asciidoctor/doctest/base_examples_suite'
require 'asciidoctor/doctest/html/example'
require 'asciidoctor/doctest/html/normalizer'
require 'corefines'
require 'nokogiri'

using Corefines::Object[:blank?, :presence, :then]
using Corefines::String::concat!

module Asciidoctor::DocTest
  module HTML
    ##
    # Subclass of {BaseExamplesSuite} for HTML-based backends.
    #
    # @example Format of the example's header
    #   <!-- .example-name
    #     Any text that is not the example's name or an option is considered
    #     as a description.
    #     :option_1: value 1
    #     :option_2: value 1
    #     :option_2: value 2
    #     :boolean_option:
    #   -->
    #   <p>The example's content in <strong>HTML</strong>.</p>
    #
    #   <div class="note">The trailing new line (below this) will be removed.</div>
    #
    class ExamplesSuite < BaseExamplesSuite

      def initialize(file_ext: '.html', paragraph_xpath: './p/node()', **kwargs)
        super file_ext: file_ext, **kwargs
        @paragraph_xpath = paragraph_xpath
      end

      def parse(input, group_name)
        examples = []
        current = create_example(nil)
        in_comment = false

        input.each_line do |line|
          line.chomp!
          if line =~ /^<!--\s*\.([^ \n]+)/
            name = $1
            current.content.chomp!
            examples << (current = create_example([group_name, name]))
            in_comment = true
          elsif in_comment
            if line =~ /^\s*:([^:]+):(.*)/
              current[$1.to_sym] = $2.blank? ? true : $2.strip
            else
              desc = line.rstrip.chomp('-->').strip
              (current.desc ||= '').concat!(desc, "\n") unless desc.empty?
            end
          else
            current.content.concat!(line, "\n")
          end
          in_comment &= !line.end_with?('-->')
        end

        examples
      end

      def serialize(examples)
        Array(examples).map { |exmpl|
          header = [
            ".#{exmpl.local_name}",
            exmpl.desc.presence,
            *format_options(exmpl.opts)
          ].compact

          header_str = header.one? ? (header.first + ' ') : (header.join("\n") + "\n")
          [ "<!-- #{header_str}-->", exmpl.content.presence ].compact.join("\n") + "\n"
        }.join("\n")
      end

      def create_example(*args)
        Example.new(*args)
      end

      def convert_example(example, opts, converter)
        # The header & footer are excluded by default; always enable for document examples.
        header_footer = !!opts[:header_footer] || example.name.start_with?('document')

        # When asserting inline examples, defaults to ignore paragraph "wrapper".
        includes = opts[:include] || (@paragraph_xpath if example.name.start_with? 'inline_')

        converter.call(example.content, header_footer: header_footer)
          .then { |s| parse_html s, !header_footer }
          .then { |h| find_nodes h, includes }
          .then { |h| remove_nodes h, opts[:exclude] }
          .then { |h| h.normalize! }
          .then { |h| HtmlBeautifier.beautify h }
          .then { |h| create_example example.name, content: h, opts: opts }
      end

      protected

      def find_nodes(html, xpaths)
        Array(xpaths).reduce(html) do |htm, xpath|
          # XPath returns NodeSet, but we need DocumentFragment, so convert it again.
          parse_html htm.xpath(xpath).to_html
        end
      end

      def remove_nodes(html, xpaths)
        return html unless xpaths

        Array(xpaths).each_with_object(html.clone) do |xpath, htm|
          htm.xpath(xpath).remove
        end
      end

      def parse_html(str, fragment = true)
        fragment ? ::Nokogiri::HTML.fragment(str) : ::Nokogiri::HTML.parse(str)
      end
    end
  end
end
