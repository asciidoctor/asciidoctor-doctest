require 'nokogiri'
require 'asciidoctor/doctest/base_generator'
require 'asciidoctor/doctest/html_beautifier'
require 'asciidoctor/doctest/html_normalizer'
require 'asciidoctor/doctest/example'

module Asciidoctor
  module DocTest
    ##
    # Generator of output examples for HTML-based backends (templates).
    class HtmlGenerator < BaseGenerator

      ##
      # (see BaseGenerator#initialize)
      def initialize(output_suite_parser = HtmlSuiteParser,
                     input_suite_parser = AsciidocSuiteParser)
        super
      end

      def render_example(input_exmpl, output_exmpl = nil)
        output_exmpl ||= Example.new(input_exmpl.name)
        output_exmpl[:header_footer] = true if input_exmpl.name.start_with?('document')
        super
      end

      def render_asciidoc(text, opts = {})
        nokogiri = opts[:header_footer] ? Nokogiri::HTML : Nokogiri::HTML::DocumentFragment
        HtmlBeautifier.beautify nokogiri.parse(super).normalize!
      end
    end
  end
end
