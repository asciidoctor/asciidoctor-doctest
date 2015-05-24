require 'pathname'

module Asciidoctor
  module DocTest

    @examples_path = Pathname.new(
      '../../data/examples/asciidoc').expand_path(__dir__).to_s.freeze

    # @return [Array<String>] paths of the built-in input examples. It always
    #   returns a new array.
    def self.examples_path
      [ @examples_path ]
    end
  end
end

# Allow to use shorten module name.
DocTest = Asciidoctor::DocTest unless defined? DocTest

require 'asciidoctor/doctest/version'
require 'asciidoctor/doctest/example'
require 'asciidoctor/doctest/generator'
require 'asciidoctor/doctest/rake_tasks'
require 'asciidoctor/doctest/test_reporter'
require 'asciidoctor/doctest/tester'
require 'asciidoctor/doctest/io'
require 'asciidoctor/doctest/html/converter'
