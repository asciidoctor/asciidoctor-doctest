module Enumerable

  ##
  # Sends a message to each element and collects the result.
  #
  # @example
  #   [1, 2, 3].map_send(:+, 3) #=> [4, 5, 6]
  #
  # @param method_name [Symbol] name of the public method to call.
  # @param args arguments to pass to the method.
  # @param block [Proc] block to pass to the method.
  # @return [Enumerable]
  #
  def map_send(method_name, *args, &block)
    map { |e| e.public_send(method_name, *args, &block) }
  end
end
