require 'asciidoctor'
require 'asciidoctor/doctest/no_fallback_template_converter'
require 'corefines'

using Corefines::Hash[:rekey, :+]
using Corefines::Object::blank?

module Asciidoctor
  module DocTest
    ##
    # This class is basically a wrapper for +Asciidoctor.convert+ that allows to
    # preset and validate some common parameters.
    class AsciidocConverter

      # @return [Hash] the default options to be passed to Asciidoctor.
      attr_reader :default_opts

      ##
      # @param opts [Hash] the default options to be passed to Asciidoctor.
      #        For a complete list of all available options see the
      #        Asciidoctor's documentation
      #
      # @option opts :backend [#to_s, nil] the name of the tested backend.
      # @option opts :backend_name [#to_s, nil] alias for the +:backend+.
      #
      # @option opts :converter [Class, Asciidoctor::Converter::Base, nil]
      #         the backend's converter class (or its instance). When not
      #         specified, the default converter for the specified backend is
      #         used.
      #
      # @option opts :template_dirs [Array<String>, String] path of the
      #         directory (or multiple directories) where to look for the
      #         backend's templates. Relative paths are referenced from the
      #         working directory.
      #
      # @option opts :templates_fallback [Boolean] allow to fall back to using
      #         an appropriate built-in converter when there is no required
      #         template in the tested backend?
      #         This is actually a default behaviour in Asciidoctor, but since
      #         it's inappropriate for testing of custom backends, it's
      #         disabled by default.
      #
      # @option opts :safe [Symbol] the safe mode, one of +:unsafe+, +:safe+,
      #         +:server+, or +:secure+. Default is +:safe+.
      #
      # @raise [ArgumentError] if some path from the +template_dirs+ doesn't
      #        exist or is not a directory.
      #
      def initialize(opts = {})
        opts = opts.rekey(&:to_sym).rekey(:backend_name => :backend)

        template_dirs = Array(opts[:template_dirs]).freeze
        template_dirs.each do |path|
          fail ArgumentError, "Templates directory '#{path}' doesn't exist!" unless Dir.exist? path
        end

        unless template_dirs.empty?
          opts[:template_dirs] = template_dirs
          opts[:converter] ||= NoFallbackTemplateConverter unless opts[:templates_fallback]
        end

        opts[:safe] ||= :safe
        opts.delete(:backend) if opts[:backend].blank?

        @default_opts = opts
      end

      ##
      # Converts the given +text+ into AsciiDoc syntax with Asciidoctor using
      # the tested backend.
      #
      # @param text [#to_s] the input text in AsciiDoc syntax.
      # @param opts [Hash] options to pass to Asciidoctor. This will be merged
      #        with {#default_opts} with precedence of +opts+.
      # @return [String] converted input.
      #
      def convert(text, opts = {})
        Asciidoctor.convert(text.to_s, @default_opts + opts)
      end

      alias_method :opts, :default_opts
      alias_method :call, :convert
    end
  end
end
