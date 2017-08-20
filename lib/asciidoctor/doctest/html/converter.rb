# frozen_string_literal: false
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
        opts = input_exmpl.opts.merge(output_exmpl.opts)

        # The header & footer are excluded by default; always enable for document examples.
        opts[:header_footer] ||= input_exmpl.name.start_with?('document')

        # When asserting inline examples, defaults to ignore paragraph "wrapper".
        opts[:include] ||= (@paragraph_xpath if input_exmpl.name.start_with? 'inline_')

        actual = convert(input_exmpl.content, header_footer: opts[:header_footer])
          .then { |s| parse_html s }
          .then { |h| find_nodes h, opts[:include] }
          .then { |h| remove_nodes h, opts[:exclude] }
          .then { |h| normalize h }

        expected = normalize(output_exmpl.content)

        [actual, expected]
      end

      protected

      def normalize(content)
        content = parse_html(content) if content.is_a? String

        has_content_type = !!meta_content_type(content)
        result = HtmlBeautifier.beautify(content.normalize!)

        # XXX: Nokogiri injects meta tag with Content-Type into rendered HTML
        # document. This nasty hack removes that tag from the result if not
        # present in the original HTML.
        if !has_content_type && content.is_a?(Nokogiri::HTML::Document)
          result.sub!(/^\s*<meta http-equiv="Content-Type" content="[^"]+"\s*\/?>\n/i, '')
        end

        result
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

      def parse_html(str)
        if str =~ /^\s*<!DOCTYPE\s/
          ::Nokogiri::HTML.parse(str)
        else
          ::Nokogiri::HTML.fragment(str)
        end
      end

      private

      ##
      # Searches <tt><meta http-equiv="Content-Type" content="..."></tt>
      # element in the given HTML document.
      #
      # @param html [Nokogiri::HTML::Document, Nokogiri::HTML::DocumentFragment]
      # @return [Nokogiri::XML::Element, nil]
      def meta_content_type(html)
        html.xpath('//meta[@http-equiv and boolean(@content)]').find do |node|
          node['http-equiv'] =~ /\AContent-Type\z/i
        end
      end
    end
  end
end
