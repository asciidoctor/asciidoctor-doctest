require 'asciidoctor/doctest/base_examples_suite'
require 'corefines'

using Corefines::Enumerable::map_send
using Corefines::Object::blank?
using Corefines::String::concat!

module Asciidoctor::DocTest
  module Latex
    ##
    # Subclass of {BaseExamplesSuite} for *TeX-based backends.
    #
    # @example Format of the example's header.
    #   %== .example_name
    #   % Any text that is not the example's name or an option is considered
    #   % as a description.
    #   % :option_1: value 1
    #   % :option_2: value 1
    #   % :option_2: value 2
    #   % :boolean_option:
    #   %==
    #   The example's content in \LaTeX.
    #
    #   The trailing new line (below this) will be removed.
    #
    # @example Format of the example's header with name only.
    #   %== .example_name ==%
    #   The example's content in \LaTeX.
    #
    class ExamplesSuite < BaseExamplesSuite

      def initialize(file_ext: '.tex', **kwargs)
        super
      end

      def parse(input, group_name)
        examples = []
        current = create_example(nil)
        in_comment = false

        input.each_line do |line|
          line.chomp!
          if line =~ /^%==\s*\.([^ \n=]+)/
            name = $1
            current.content.chomp!
            examples << (current = create_example([group_name, name]))
            in_comment = !line.end_with?('==%')
          elsif in_comment
            case line
            when /^%==/
              in_comment = false
            when /^%\s*:([^:]+):(.*)/
              current[$1.to_sym] = $2.blank? ? true : $2.strip
            when /^%(.*)/
              desc = $1.strip
              (current.desc ||= '').concat!(desc, "\n") unless desc.empty?
            else
              fail "Header is malformed! Line starting with '%' expected, but got: #{line}"
            end
          else
            current.content.concat!(line, "\n")
          end
        end

        examples
      end

      def serialize(examples)
        Array(examples).map { |exmpl|
          lines = exmpl.desc.lines.map(&:chomp)
          lines.push(*format_options(exmpl.opts))

          if lines.empty?
            lines << "%== .#{exmpl.local_name} ==%"
          else
            lines.map_send(:prepend, '% ')
            lines.unshift("%== .#{exmpl.local_name}").push('%==')
          end
          lines << exmpl.to_s unless exmpl.empty?

          lines.join("\n") + "\n"
        }.join("\n")
      end

      # TODO: implement some postprocessing to filter out boilerplate
      def convert_example(example, opts, renderer)
        content = renderer.render(example.to_s)
        create_example example.name, content: content, opts: opts
      end
    end
  end
end
