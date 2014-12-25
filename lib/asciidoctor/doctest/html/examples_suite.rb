require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/blank'
require 'asciidoctor/doctest/base_examples_suite'
require 'asciidoctor/doctest/core_ext'
require 'asciidoctor/doctest/html/example'
require 'asciidoctor/doctest/html/normalizer'
require 'nokogiri'

module Asciidoctor::DocTest
  module HTML
    ##
    # Subclass of {BaseExamplesSuite} for HTML-based backends.
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
            elsif !line.start_with?('//')
              desc = line.rstrip.chomp('-->').strip
              (current.desc ||= '').concat(desc, "\n") unless desc.empty?
            end
          else
            current.content.concat(line, "\n")
          end
          in_comment &= !line.end_with?('-->')
        end

        examples
      end

      def serialize(examples)
        Array.wrap(examples).map { |exmpl|
          header = [ ".#{exmpl.local_name}", exmpl.desc.presence ].compact

          exmpl.opts.each do |name, vals|
            Array.wrap(vals).each do |val|
              header << (val == true ? ":#{name}:" : ":#{name}: #{val}")
            end
          end
          header_str = header.one? ? (header.first + ' ') : (header.join("\n") + "\n")

          [ "<!-- #{header_str}-->", exmpl.content.presence ].compact.join("\n") + "\n"
        }.join("\n")
      end

      def create_example(*args)
        Example.new(*args)
      end

      def convert_example(example, opts, renderer)
        header_footer = !!opts[:header_footer] || example.name.start_with?('document')

        html = renderer.convert(example.to_s, header_footer: header_footer)
        html = parse_html(html, !header_footer)

        # When asserting inline examples, ignore paragraph "wrapper".
        includes = opts[:include] || (@paragraph_xpath if example.name.start_with? 'inline_')

        Array.wrap(includes).each do |xpath|
          # XPath returns NodeSet, but we need DocumentFragment, so convert it again.
          html = parse_html(html.xpath(xpath).to_html)
        end

        Array.wrap(opts[:exclude]).each do |xpath|
          html.xpath(xpath).remove
        end

        html.normalize!

        create_example example.name, content: html.to_s, opts: opts
      end

      private

      def parse_html(str, fragment = true)
        fragment ? ::Nokogiri::HTML.fragment(str) : ::Nokogiri::HTML.parse(str)
      end
    end
  end
end
