require 'asciidoctor'
require 'asciidoctor/converter/template'

module Asciidoctor
  module DocTest
    ##
    # @private
    # Adapter for +Asciidoctor::Converter::TemplateConverter+.
    class TemplateConverterAdapter < SimpleDelegator

      NOT_FOUND_MARKER = '--TEMPLATE NOT FOUND--'

      ##
      # Returns a new instance of +TemplateConverterAdapter+ that delegates
      # to an instance of +Asciidoctor::Converter::TemplateConverter+ that is
      # created using the given arguments.
      #
      # @param backend [String] name of the backend.
      # @param opts [Hash] options.
      #
      def initialize(backend, opts = {})
        super Asciidoctor::Converter::TemplateConverter.new(backend, opts[:template_dirs], opts)
      end

      ##
      # Delegates to the template converter and returns results, or prints
      # warning and returns {NOT_FOUND_MARKER} if there is no template to
      # handle the specified +template_name+.
      #
      # @param node [AbstractNode] the node to convert.
      # @param template_name [String] name of the template to use. If not
      #        specified, the node's name is used as default.
      # @param opts [Hash] an optional Hash that is passed as local variables
      #        to the template.
      # @return [String] result from rendering the template, or
      #         {NOT_FOUND_MARKER} if template not available.
      #
      def convert(node, template_name = nil, opts = {})
        template_name ||= node.node_name

        if handles? template_name
          super
        else
          warn "Could not find a custom template to handle template_name: #{template_name}"
          NOT_FOUND_MARKER
        end
      end

      # Alias for backward compatibility.
      alias :convert_with_options :convert
    end
  end
end
