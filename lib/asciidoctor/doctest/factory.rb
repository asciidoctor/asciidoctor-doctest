module Asciidoctor::DocTest
  module Factory

    ##
    # Registers the given class in the factory under the specified name.
    #
    # @param name [#to_sym] the name under which to register the class.
    # @param klass [Class] the class to register.
    # @param default_opts [Hash] default options to be passed into the class'
    #        initializer. May be overriden by +opts+ passed to {.create}.
    # @return [self]
    #
    def register(name, klass, default_opts = {})
      @factory_registry ||= {}
      @factory_registry[name.to_sym] = ->(opts) { klass.new(default_opts.merge(opts)) }
      self
    end

    ##
    # @param name [#to_sym] name of the class to create.
    # @param opts [Hash] options to be passed into the class' initializer.
    # @return [Object] a new instance of the class registered under the
    #   specified name.
    # @raise ArgumentError if no class was found for the given name.
    #
    def create(name, opts = {})
      @factory_registry ||= {}

      if (obj = @factory_registry[name.to_sym])
        obj.call(opts)
      else
        fail ArgumentError, "No class registered with name: #{name}"
      end
    end
  end
end
