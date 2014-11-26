require 'pathname'

module Asciidoctor
  module DocTest

    @examples_path  = [
      Pathname.new('../../data/examples/asciidoc').expand_path(__dir__).to_s
    ]

    class << self

      # @return [Array<String>] paths of the directories where to look for the
      #   examples suites. Use +unshift+ to add your paths before the built-in
      #   reference input examples (default: +["{asciidoctor-doctest}/data/examples/asciidoc"]+).
      attr_accessor :examples_path
    end
  end
end

require 'asciidoctor/doctest/version'
require 'asciidoctor/doctest/example'
require 'asciidoctor/doctest/base_suite_parser'
require 'asciidoctor/doctest/asciidoc_suite_parser'
require 'asciidoctor/doctest/html_suite_parser'
require 'asciidoctor/doctest/base_test'
require 'asciidoctor/doctest/html_test'
require 'asciidoctor/doctest/base_generator'
require 'asciidoctor/doctest/html_generator'
require 'asciidoctor/doctest/generator_task'
