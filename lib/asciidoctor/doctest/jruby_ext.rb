# Workarounds for JRuby.
require 'delegate'

# @private
class SimpleDelegator

  # https://github.com/jruby/jruby/issues/2412
  def warn(*msg)
    Kernel.warn(*msg)
  end
end
