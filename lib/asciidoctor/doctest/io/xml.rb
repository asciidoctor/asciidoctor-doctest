# frozen_string_literal: false
require 'asciidoctor/doctest/io/base'
require 'corefines'

using Corefines::Object[:blank?, :presence]
using Corefines::String::concat!

module Asciidoctor::DocTest
  module IO
    ##
    # Subclass of {IO::Base} for XML-based backends.
    #
    # @example Format of the example's header
    #   <!-- .example-name
    #     Any text that is not the example's name or an option is considered
    #     as a description.
    #     :option_1: value 1
    #     :option_2: value 1
    #     :option_2: value 2
    #     :boolean_option:
    #   -->
    #   <p>The example's content in <strong>HTML</strong>.</p>
    #
    #   <div class="note">The trailing new line (below this) will be removed.</div>
    #
    class XML < Base

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
            else
              desc = line.rstrip.chomp('-->').strip
              (current.desc ||= '').concat!(desc, "\n") unless desc.empty?
            end
          else
            current.content.concat!(line, "\n")
          end
          in_comment &= !line.end_with?('-->')
        end

        examples
      end

      def serialize(examples)
        Array(examples).map { |exmpl|
          header = [
            ".#{exmpl.local_name}",
            exmpl.desc.presence,
            *format_options(exmpl.opts)
          ].compact

          header_str = header.one? ? (header.first + ' ') : (header.join("\n") + "\n")
          [ "<!-- #{header_str}-->", exmpl.content.presence ].compact.join("\n") + "\n"
        }.join("\n")
      end
    end
  end
end
