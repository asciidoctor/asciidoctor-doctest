require 'asciidoctor/doctest/base_example'
require 'asciidoctor/doctest/html/html_beautifier'
require 'asciidoctor/doctest/html/normalizer'
require 'nokogiri'

module Asciidoctor::DocTest
  module HTML
    ##
    # Subclass of {BaseExample} for HTML-based backends.
    class Example < BaseExample

      def content_normalized
        Nokogiri::HTML.fragment(content).normalize!.to_s
      end

      def to_s
        HtmlBeautifier.beautify content_normalized
      end
    end
  end
end
