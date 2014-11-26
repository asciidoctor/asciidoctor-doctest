require 'active_support/core_ext/array/wrap'
require 'asciidoctor/doctest/base_test'
require 'asciidoctor/doctest/html_beautifier'
require 'asciidoctor/doctest/html_normalizer'
require 'nokogiri'

module Asciidoctor
  module DocTest
    ##
    # Base class for testing HTML-based backends (templates).
    class HtmlTest < BaseTest

      PARAGRAPH_XPATH = './p/node()'

      ##
      # (see BaseTest#generate_tests!)
      def self.generate_tests!(output_suite_parser = HtmlSuiteParser,
                               input_suite_parser = AsciidocSuiteParser)
        super
      end

      ##
      # (see BaseTest#test_example)
      def test_example(input_exmpl, output_exmpl)
        header_footer = !!output_exmpl[:header_footer] || name.start_with?('document')
        actual = render_asciidoc(input_exmpl, { header_footer: header_footer })

        actual = parse_html(actual, !header_footer)
        expected = parse_html(output_exmpl.to_s)

        # When asserting inline examples, ignore paragraph "wrapper".
        output_exmpl[:include] ||= PARAGRAPH_XPATH if name.start_with? 'inline_'

        actual = select_with_xpath(actual, output_exmpl[:include])
        actual = remove_with_xpath(actual, output_exmpl[:exclude])

        desc = input_exmpl.desc || output_exmpl.desc

        assert_equal expected.to_html, actual.to_html, desc
      end

      ##
      # Returns subnodes of the +html+ selected by the Xpath expression(s).
      #
      # @param html [Nokogiri::HTML::DocumentFragment]
      # @param xpath [String, Array<String>, nil]
      # @return [Nokogiri::HTML::DocumentFragment]
      #
      def select_with_xpath(html, xpath)
        Array.wrap(xpath).each do |xpath|
          # xpath returns NodeSet, but we need DocumentFragment, so convert it again
          html = parse_html(html.xpath(xpath).to_html)
        end
        html
      end

      ##
      # Returns copy of the +html+ without (sub)nodes specified by the XPath
      # expression(s).
      #
      # @param html (see #select_nodes)
      # @param xpath (see #select_nodes)
      # @return (see #select_nodes)
      #
      def remove_with_xpath(html, xpath)
        html = html.dup
        Array.wrap(xpath).each do |xpath|
          html.xpath(xpath).each(&:remove)
        end
        html
      end

      ##
      # Parses and normalizes the HTML input.
      #
      # @param input [String]
      # @param fragment [Boolean] whether +input+ is a HTML fragment, or
      #        a complete HTML document. (default: true)
      # @return [Nokogiri::HTML::DocumentFragment] a parsed HTML fragment.
      # @return [Nokogiri::HTML::Document] a parsed HTML document.
      #
      def parse_html(input, fragment = true)
        nokogiri = fragment ? Nokogiri::HTML::DocumentFragment : Nokogiri::HTML
        nokogiri.parse(input).normalize!
      end

      ##
      # Returns a human-readable (formatted) version of the +html+.
      # @note Overrides method from +Minitest::Assertions+.
      def mu_pp(html)
        HtmlBeautifier.beautify html
      end
    end
  end
end
