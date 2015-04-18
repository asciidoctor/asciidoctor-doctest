require 'pathname'

module Asciidoctor
  module DocTest

    BUILTIN_EXAMPLES_PATH = Pathname.new(
      '../../data/examples/asciidoc').expand_path(__dir__).to_s.freeze

    @examples_path = [ BUILTIN_EXAMPLES_PATH ]

    class << self
      # @return [Array<String>] paths of the directories where to look for the
      #   examples suites. Use +unshift+ to add your paths before the built-in
      #   reference input examples (default: +["{asciidoctor-doctest}/data/examples/asciidoc"]+).
      attr_accessor :examples_path
    end
  end
end

# Allow to use shorten module name.
DocTest = Asciidoctor::DocTest unless defined? DocTest

require 'asciidoctor/doctest/version'
require 'asciidoctor/doctest/base_example'
require 'asciidoctor/doctest/base_examples_suite'
require 'asciidoctor/doctest/generator'
require 'asciidoctor/doctest/generator_task'
require 'asciidoctor/doctest/rake_tasks'
require 'asciidoctor/doctest/test'
require 'asciidoctor/doctest/asciidoc/examples_suite'
require 'asciidoctor/doctest/html/examples_suite'
