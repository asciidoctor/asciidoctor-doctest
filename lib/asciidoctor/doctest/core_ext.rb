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

class Module

  ##
  # Makes +new_name+ a new copy of the class method +old_name+.
  #
  # @param new_name [Symbol] name of the new class method to create.
  # @param old_name [Symbol] name of the existing class method to alias.
  #
  def alias_class_method(new_name, old_name)
    singleton_class.send(:alias_method, new_name, old_name)
  end
end

class String

  ##
  # Appends (concatenates) the given object to +str+.
  #
  # @param obj [String, Integer] the string, or codepoint to append.
  # @param separator [String, nil] the separator to append when this +str+ is
  #        not empty.
  # @return [String] self
  #
  def concat(obj, separator = nil)
    if separator && !self.empty?
      self << separator << obj
    else
      self << obj
    end
  end
end


# Workarounds for JRuby.
if RUBY_ENGINE == 'jruby'
  require 'delegate'

  # @private
  class SimpleDelegator

    # https://github.com/jruby/jruby/issues/2412
    def warn(*msg)
      Kernel.warn(*msg)
    end
  end
end
