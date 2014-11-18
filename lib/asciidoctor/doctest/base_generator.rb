require 'asciidoctor'
require 'asciidoctor/doctest/core_ext'
require 'colorize'

module Asciidoctor
  module DocTest
    ##
    # Base generator of testing examples.
    class BaseGenerator

      # Glob pattern that matches all the examples.
      ALL_PATTERN = '*:*'

      # @return [BaseSuiteParser] an instance of the suite parser to be used
      #   for reading the reference Asciidoctor examples.
      attr_accessor :asciidoc_suite_parser

      # @return [#<<] destination where to write log messages
      #   (default: +$stdout+).
      attr_accessor :log_to

      # @return [BaseSuiteParser] an instance of the suite parser to be used
      #   for reading and writing the tested examples.
      attr_accessor :tested_suite_parser

      # @return [Array<String>] path of the directory where to look for the
      #   backend's templates (default: {DocTest.templates_path}).
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
      # @param tested_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading and writing the
      #        tested examples. If class is given, then it's instantiated with
      #        zero arguments.
      #
      # @param asciidoc_suite_parser [BaseSuiteParser, Class] the suite parser
      #        class (or its instance) to be used for reading the reference
      #        Asciidoctor examples. If class is given, then it's instantiated
      #        with zero arguments.
      #
      def initialize(tested_suite_parser, asciidoc_suite_parser = AsciidocSuiteParser)
        @tested_suite_parser = tested_suite_parser.with { is_a?(Class) ? new : self }
        @asciidoc_suite_parser = asciidoc_suite_parser.with { is_a?(Class) ? new : self }
        @log_to = $stdout
        # intentionally use accessor to peform validation
        templates_path ||= DocTest.templates_path
      end

      ##
      # Generates missing, or rewrite existing testing examples from the
      # Asciidoctor reference examples converted through the backend templates
      # (specified by +templates_dir+ during initialization).
      #
      # @param pattern [String] glob-like pattern to select testing examples to
      #        (re)generate (see {BaseSuiteParser#filter_examples}).
      # @param rewrite [Boolean] whether to rewrite an already existing testing
      #        example.
      #
      def generate!(pattern = ALL_PATTERN, rewrite = false)
        filter_examples(pattern).each do |suite_name, exmpl_names|

          old_suite = read_tested_suite(suite_name)
          new_suite = {}

          read_asciidoc_suite(suite_name).each do |exmpl_name, adoc_exmpl|

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
              log "#{suite_name}:#{exmpl_name} doesn't exist in Asciidoctor's reference examples!".red
              new_suite[exmpl_name] = exmpl
            end
          end

          write_tested_suite suite_name, new_suite
        end
      end

      ##
      # Renders the given +input+ in AsciiDoc syntax with Asciidoctor using the
      # tested backend, i.e. templates on the {#templates_path}.
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
          template_dirs: templates_path,
          header_footer: opts.key?(:header_footer)
        }
        Asciidoctor.render input, renderer_opts
      end

      ##
      # @private
      # Builds a log message about the testing example (not) being (re)generated.
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

      def read_asciidoc_suite(suite_name)
        @asciidoc_suite_parser.read_suite suite_name
      end

      def read_tested_suite(suite_name)
        @tested_suite_parser.read_suite suite_name
      end

      def write_tested_suite(suite_name, data)
        @tested_suite_parser.write_suite suite_name, data
      end

      def filter_examples(pattern)
        @asciidoc_suite_parser.filter_examples pattern
      end
    end
  end
end
