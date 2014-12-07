require 'asciidoctor/doctest/base_examples_suite'
require 'asciidoctor/doctest/core_ext'

module Asciidoctor::DocTest
  module Asciidoc
    ##
    # Subclass of {BaseExamplesSuite} for reference input examples.
    #
    # @example Format of the example's header
    #   // .example-name
    #   // Any text that is not the example's name is considered
    #   // as a description.
    #   The example's content in *AsciiDoc*.
    #
    #   NOTE: The trailing new line (below this) will be removed.
    #
    class ExamplesSuite < BaseExamplesSuite

      def initialize(file_ext: '.adoc', **kwargs)
        super
      end

      def parse(input, group_name)
        examples = []
        current = create_example(nil)

        input.each_line do |line|
          line.chomp!
          if line =~ %r{^//\s*\.([^ \n]+)}
            local_name = $1
            current.content.chomp!
            examples << (current = create_example([group_name, local_name]))
          elsif line =~ %r{^//\s*(.*)\s*$}
            (current.desc ||= '').concat($1, "\n")
          else
            current.content.concat(line, "\n")
          end
        end

        examples
      end
    end
  end
end
