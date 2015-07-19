require 'asciidoctor/converter/template'
require 'delegate'

module Asciidoctor
  module DocTest
    ##
    # @private
    # TemplateConverter that doesn't fallback to a built-in converter when
    # no template for a node is found.
    #
    class NoFallbackTemplateConverter < SimpleDelegator
      # NOTE: It didn't work with subclass of TemplateConverter instead of
      # delegator, I have no idea why.

      # Placeholder to be written in a rendered output in place of the node's
      # content that cannot be rendered due to missing template.
      NOT_FOUND_MARKER = '--TEMPLATE NOT FOUND--'

      def initialize(backend, opts = {})
        super Asciidoctor::Converter::TemplateConverter.new(backend, opts[:template_dirs], opts)
      end

      ##
      # Delegates to the template converter and returns results, or prints
      # warning and returns {NOT_FOUND_MARKER} if there is no template to
      # handle the specified +template_name+.
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
      alias_method :convert_with_options, :convert
    end
  end
end
