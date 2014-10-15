module Asciidoctor
  module DocTest

    @examples_path  = File.join(__dir__, '../../data/examples')
    @templates_path = Dir.pwd

    class << self
      attr_accessor :examples_path, :templates_path
    end
  end
end

require 'asciidoctor/doctest/core_ext'
require 'asciidoctor/doctest/base_suite_parser'
require 'asciidoctor/doctest/asciidoc_suite_parser'
require 'asciidoctor/doctest/html_suite_parser'
require 'asciidoctor/doctest/base_test'
require 'asciidoctor/doctest/html_test'
require 'asciidoctor/doctest/base_generator'
require 'asciidoctor/doctest/html_generator'
