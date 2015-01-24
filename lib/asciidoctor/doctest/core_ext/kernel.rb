module Kernel

  ##
  # Passes +self+ to the block and returns its result.
  #
  # @yield [self] Passes +self+ to the block.
  # @return [Object] evaluation of the block, or +self+ if no block given or
  #   +self+ is +nil+.
  def then
    if block_given? && !self.nil?
      yield self
    else
      self
    end
  end
end
