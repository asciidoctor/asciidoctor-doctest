class Object
  alias :with :instance_eval
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
