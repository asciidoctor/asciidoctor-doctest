require 'asciidoctor'
require 'asciidoctor/doctest/core_ext'
require 'asciidoctor/doctest/example'
require 'colorize'

module Asciidoctor
  module DocTest
    ##
    # Base generator of output examples.
    class BaseGenerator

      # Glob pattern that matches all the examples.
      ALL_PATTERN = '*:*'

      # @return [#to_s, nil] name of the backend to convert examples.
      attr_accessor :backend_name

      # @return [BaseSuiteParser] an instance of the suite parser to be used
      #   for reading the input AsciiDoc examples.
      attr_accessor :input_suite_parser

      # @return [#<<] output stream where to write log messages
      #   (default: +$stdout+).
      attr_accessor :log_os

      # @return [BaseSuiteParser] an instance of the suite parser to be used
      #   for reading and writing output examples.
      attr_accessor :output_suite_parser

      # @return [Array<String>] path of the directory where to look for the
      #   backend's templates.
      # @raise [StandardError] if any of the given paths doesn't exist or not
      #   a directory.
      attr_accessor :templates_path

      def templates_path=(*paths)
        paths.flatten!
        unless paths.all? { |path| Dir.exist? path }
          fail "Templates directory '#{path}' doesn't exist!"
        end
        @templates_path = paths
      end


      ##
      # Returns a new instance of BaseGenerator.
      #
      # @param output_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading and writing
      #        output examples. If class is given, then it's instantiated with
      #        zero arguments.
      #
      # @param input_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading input AsciiDoc
      #        examples. If class is given, then it's instantiated
      #        with zero arguments.
      #
      def initialize(output_suite_parser, input_suite_parser = AsciidocSuiteParser)
        @output_suite_parser = output_suite_parser.with { is_a?(Class) ? new : self }
        @input_suite_parser = input_suite_parser.with { is_a?(Class) ? new : self }
        @backend_name = nil
        @log_os = $stdout
        @templates_path = []
      end

      ##
      # Generates missing, or rewrite existing output examples from the
      # input examples converted through the tested backend.
      #
      # @param pattern [String] glob-like pattern to select examples to
      #        (re)generate (see {Example#name_match?}).
      # @param rewrite [Boolean] whether to rewrite an already existing
      #        example.
      #
      def generate!(pattern = ALL_PATTERN, rewrite = false)
        input_suite_parser.suite_names.each do |suite_name|
          inputs_by_name = input_suite_parser.read_suite(suite_name).map { |e| [e.name, e] }.to_h

          outputs = output_suite_parser.read_suite(suite_name).map do |output|
            if (input = inputs_by_name.delete(output.name))
              next output unless output.name_match? pattern

              refreshed = render_example(input, output)

              # TODO allow to customize comparison in subclasses
              if refreshed == output
                log "Unchanged #{input.name}".green
              elsif rewrite
                log "Rewriting #{input.name}".red
                output = refreshed
              else
                log "Skipping #{input.name}".yellow
              end
            else
              log "Unknown #{output.name}, doesn't exist in input examples!"
            end
            output
          end

          inputs_by_name.each_value do |input|
            log "Generating #{input.name}".magenta
            outputs << render_example(input)
          end

          output_suite_parser.write_suite suite_name, outputs
        end
      end

      def render_example(input_exmpl, output_exmpl)
        output_exmpl ||= Example.new(input_exmpl.name)

        output_exmpl.dup.tap do |e|
          opts = { header_footer: output_exmpl[:header_footer] }
          e.content = render_asciidoc(input_exmpl, opts)
        end
      end

      ##
      # (see BaseTest#render_asciidoc)
      def render_asciidoc(text, opts = {})
        renderer_opts = {
          safe: :safe,
          backend: backend_name.to_s,
          template_dirs: templates_path,
        }.merge(opts)

        Asciidoctor.render(text.to_s, renderer_opts)
      end

      ##
      # @private
      # Logs the +message+ to the destination specified by {#log_os} unless
      # +log_os+ is +nil+.
      def log(message = nil, &block)
        message ||= block.call
        log_os << " --> #{message.chomp}\n" if log_os
      end
    end
  end
end
