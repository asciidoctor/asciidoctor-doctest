require 'htmlbeautifier'

module HtmlBeautifier

  ##
  # Beautifies the +input+ HTML.
  #
  # @param input [String, #to_html]
  # @return [String] a beautified copy of the +input+.
  #
  def self.beautify(input)
    input = input.to_html unless input.is_a? String
    output = []
    Beautifier.new(output).scan(input)
    output.join
  end
end
