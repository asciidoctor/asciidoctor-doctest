require 'asciidoctor/doctest/base_examples_suite'
require 'corefines'

using Corefines::Enumerable::map_send
using Corefines::Object::blank?
using Corefines::String::concat!

module Asciidoctor::DocTest
  module Latex
    class ExamplesSuite < BaseExamplesSuite

      def initialize(file_ext: '.tex', **kwargs)
        super
      end

      # TODO use more specific delimiter for example's header to not interfere
      # with comments in LaTeX output.

      def parse(input, group_name)
        examples = []
        current = create_example(nil)

        input.each_line do |line|
          case line.chomp!
          when /^%\s*\.([^ \n]+)/
            name = $1
            current.content.chomp!
            examples << (current = create_example([group_name, name]))
          when /^%\s*:([^:]+):(.*)/
            current[$1.to_sym] = $2.blank? ? true : $2.strip
          when /^%\s*(.*)/
            desc = $1.strip
            (current.desc ||= '').concat!(desc, "\n") unless desc.empty?
          else
            current.content.concat!(line, "\n")
          end
        end

        examples
      end

      def serialize(examples)
        Array(examples).map { |exmpl|
          lines = [".#{exmpl.local_name}", *exmpl.desc.lines.map(&:chomp)]

          lines.push(*format_options(exmpl.opts))
          lines.map_send(:prepend, '% ')
          lines.push(exmpl.to_s) unless exmpl.empty?

          lines.join("\n") + "\n"
        }.join("\n")
      end

      # TODO implement some postprocessing to filter out boilerplate
      def convert_example(example, opts, renderer)
        content = renderer.render(example.to_s)
        create_example example.name, content: content, opts: opts
      end
    end
  end
end
