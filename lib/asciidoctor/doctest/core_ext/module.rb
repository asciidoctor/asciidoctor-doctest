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
