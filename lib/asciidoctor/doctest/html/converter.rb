require 'asciidoctor/doctest/html_normalizer'
require 'corefines'
require 'htmlbeautifier'
require 'nokogiri'

using Corefines::Object::then

module Asciidoctor::DocTest
  module HTML
    class Converter < AsciidocConverter

      def initialize(paragraph_xpath: './p/node()', **opts)
        @paragraph_xpath = paragraph_xpath
        super opts
      end

      def convert_examples(input_exmpl, output_exmpl)
        opts = output_exmpl.opts.dup

        # The header & footer are excluded by default; always enable for document examples.
        opts[:header_footer] ||= input_exmpl.name.start_with?('document')

        # When asserting inline examples, defaults to ignore paragraph "wrapper".
        opts[:include] ||= (@paragraph_xpath if input_exmpl.name.start_with? 'inline_')

        actual = convert(input_exmpl.content, header_footer: opts[:header_footer])
          .then { |s| parse_html s, !opts[:header_footer] }
          .then { |h| find_nodes h, opts[:include] }
          .then { |h| remove_nodes h, opts[:exclude] }
          .then { |h| normalize(h) }

        expected = normalize(output_exmpl.content)

        [actual, expected]
      end

      protected

      def normalize(content)
        content = parse_html(content) if content.is_a? String
        HtmlBeautifier.beautify(content.normalize!)
      end

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
