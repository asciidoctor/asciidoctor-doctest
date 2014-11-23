require 'asciidoctor'
require 'asciidoctor/doctest/core_ext'
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

      # @return [#<<] destination where to write log messages
      #   (default: +$stdout+).
      attr_accessor :log_to

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
        @log_to = $stdout
        @templates_path = []
      end

      ##
      # Generates missing, or rewrite existing output examples from the
      # input examples converted through the tested backend.
      #
      # @param pattern [String] glob-like pattern to select examples to
      #        (re)generate (see {BaseSuiteParser#filter_examples}).
      # @param rewrite [Boolean] whether to rewrite an already existing
      #        example.
      #
      def generate!(pattern = ALL_PATTERN, rewrite = false)
        filter_examples(pattern).each do |suite_name, exmpl_names|

          old_suite = read_output_suite(suite_name)
          new_suite = {}

          read_input_suite(suite_name).each do |exmpl_name, adoc_exmpl|

            exmpl = old_suite.delete(exmpl_name) || {}
            new_suite[exmpl_name] = exmpl unless exmpl.empty?

            if exmpl_names.include? exmpl_name
              old_content = exmpl[:content] || ''
              new_content = render_asciidoc(adoc_exmpl.delete(:content), suite_name, adoc_exmpl)

              name = "#{suite_name}:#{exmpl_name}"
              log status_message(name, old_content, new_content, rewrite)

              if old_content.empty? || rewrite
                new_suite[exmpl_name] = exmpl.merge(content: new_content)
              end
            end
          end

          unless old_suite.empty?
            old_suite.each do |exmpl_name, exmpl|
              log "#{suite_name}:#{exmpl_name} doesn't exist in input examples!".red
              new_suite[exmpl_name] = exmpl
            end
          end

          write_output_suite suite_name, new_suite
        end
      end

      ##
      # Renders the given +input+ in AsciiDoc syntax with Asciidoctor using the
      # tested backend.
      #
      # @param input [String] the input text in AsciiDoc syntax.
      # @param suite_name [String] name of the examples suite that is a source
      #        of the given +input+.
      # @param opts [Hash]
      # @option opts :header_footer [Boolean] whether to render a full document.
      # @return [String] the input text rendered in the tested syntax.
      #
      def render_asciidoc(input, suite_name = '', opts = {})
        renderer_opts = {
          safe: :safe,
          backend: (backend_name.to_s if backend_name),
          template_dirs: templates_path,
          header_footer: opts.key?(:header_footer)
        }
        Asciidoctor.render input, renderer_opts
      end

      ##
      # @private
      # Builds a log message about the example (not) being (re)generated.
      def status_message(name, old_content, new_content, overwrite)
        msg = if old_content.empty?
                "Generating #{name}".magenta
              else
                if old_content.chomp == new_content.chomp
                  "Unchanged #{name}".green
                elsif overwrite
                  "Rewriting #{name}".red
                else
                  "Skipping #{name}".yellow
                end
              end
        " --> #{msg}"
      end

      ##
      # @private
      # Logs the +message+ to the destination specified by {#log_to} unless
      # +log_to+ is +nil+.
      def log(message = nil, &block)
        message ||= block.call
        @log_to << message.chomp + "\n" if @log_to
      end

      def read_input_suite(suite_name)
        @input_suite_parser.read_suite suite_name
      end

      def read_output_suite(suite_name)
        @output_suite_parser.read_suite suite_name
      end

      def write_output_suite(suite_name, data)
        @output_suite_parser.write_suite suite_name, data
      end

      def filter_examples(pattern)
        @input_suite_parser.filter_examples pattern
      end
    end
  end
end
