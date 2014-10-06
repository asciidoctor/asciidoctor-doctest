module AdocSpec

  @examples_path  = File.join(__dir__, '../data/examples')
  @templates_path = File.join(__dir__, '../data/haml')

  class << self
    attr_accessor :examples_path, :templates_path
  end
end

require 'adocspec/base'
require 'adocspec/asciidoc'
require 'adocspec/html'
