module AdocSpec

  @examples_path  = File.join(__dir__, '../data/examples')
  @templates_path = File.join(__dir__, '../data/haml')

  class << self
    attr_accessor :examples_path, :templates_path
  end
end

require 'adocspec/base_suite_parser'
require 'adocspec/asciidoc_suite_parser'
require 'adocspec/html_suite_parser'
require 'adocspec/base_test'
require 'adocspec/html_test'
