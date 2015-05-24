require 'asciidoctor/doctest/base_examples_suite'
require 'corefines'

using Corefines::Enumerable::map_send
using Corefines::Object[:blank?, :presence]
using Corefines::String::concat!

module Asciidoctor::DocTest
  module IO
    ##
    # Subclass of {BaseExamplesSuite} for reference input examples.
    #
    # @example Format of the example's header
    #   // .example-name
    #   // Any text that is not the example's name or an option is considered
    #   // as a description.
    #   // :option_1: value 1
    #   // :option_2: value 1
    #   // :option_2: value 2
    #   // :boolean_option:
    #   The example's content in *AsciiDoc*.
    #
    #   NOTE: The trailing new line (below this) will be removed.
    #
    class Asciidoc < BaseExamplesSuite

      def initialize(file_ext: '.adoc', **kwargs)
        super
      end

      def parse(input, group_name)
        examples = []
        current = create_example(nil)

        input.each_line do |line|
          case line.chomp!
          when %r{^//\s*\.([^ \n]+)}
            local_name = $1
            current.content.chomp!
            examples << (current = create_example([group_name, local_name]))
          when %r{^//\s*:([^:]+):(.*)}
            current[$1.to_sym] = $2.blank? ? true : $2.strip
          when %r{^//\s*(.*)\s*$}
            (current.desc ||= '').concat!($1, "\n")
          else
            current.content.concat!(line, "\n")
          end
        end

        examples
      end

      def serialize(examples)
        Array(examples).map { |exmpl|
          Array.new.push(".#{exmpl.local_name}")
            .push(*exmpl.desc.lines.map(&:chomp))
            .push(*format_options(exmpl.opts))
            .map_send(:prepend, '// ')
            .push(exmpl.content.presence)
            .compact
            .join("\n")
            .concat("\n")
        }.join("\n")
      end
    end
  end
end
