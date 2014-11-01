require 'nokogiri'
require 'asciidoctor/doctest/base_test'
require 'asciidoctor/doctest/html_beautifier'
require 'asciidoctor/doctest/html_normalizer'

module Asciidoctor
  module DocTest
    ##
    # Base class for testing HTML-based backends (templates).
    class HtmlTest < BaseTest

      ##
      # (see BaseTest#assert_example)
      def assert_example(expected, actual, opts)
        actual = parse_html(actual, !opts.key?(:header_footer))
        expected = parse_html(expected)

        # When asserting inline examples, ignore paragraph "wrapper".
        opts[:include] ||= ['.//p/node()'] if name.start_with? 'inline_'

        # Select nodes specified by the XPath expression.
        opts.fetch(:include, []).each do |xpath|
          # xpath returns NodeSet, but we need DocumentFragment, so convert it again
          actual = parse_html(actual.xpath(xpath).to_html)
        end

        # Remove nodes specified by the XPath expression.
        opts.fetch(:exclude, []).each do |xpath|
          actual.xpath(xpath).each(&:remove)
        end

        assert_equal expected.to_html, actual.to_html, opts[:desc]
      end

      ##
      # Returns a human-readable (formatted) version of +html+.
      # @note Overrides method from +Minitest::Assertions+.
      def mu_pp(html)
        HtmlBeautifier.beautify html
      end

      ##
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
      # (see BaseTest#render_asciidoc)
      def render_asciidoc(text, opts = {})
        # Render 'document' examples as a full document with header and footer.
        opts[:header_footer] = true if name.start_with? 'document'
        super
      end
    end
  end
end
