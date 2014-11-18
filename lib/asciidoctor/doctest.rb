require 'pathname'

module Asciidoctor
  module DocTest

    @examples_path  = [
      Pathname.new('../../data/examples/asciidoc').expand_path(__dir__).to_s
    ]
    @templates_path = []

    class << self

      # @return [Array<String>] paths of the directories where to look for the
      #   testing examples. Use +unshift+ to add your additional paths before
      #   the default built-in Asciidoctor examples path.
      attr_accessor :examples_path

      # @return [Array<String>] paths of the directories where to look for the
      #   templates (backends).
      attr_accessor :templates_path
    end
  end
end

require 'asciidoctor/doctest/version'
require 'asciidoctor/doctest/base_suite_parser'
require 'asciidoctor/doctest/asciidoc_suite_parser'
require 'asciidoctor/doctest/html_suite_parser'
require 'asciidoctor/doctest/base_test'
require 'asciidoctor/doctest/html_test'
require 'asciidoctor/doctest/base_generator'
require 'asciidoctor/doctest/html_generator'
require 'asciidoctor/doctest/generator_task'
