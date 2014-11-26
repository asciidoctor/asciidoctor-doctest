require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/instance_variables'

module Asciidoctor
  module DocTest
    ##
    # This class represents the test example.
    class Example

      NAME_SEPARATOR = ':'

      # @return [String] the first part of the name.
      attr_accessor :suite_name

      # @return [String] the second part of the name.
      attr_accessor :local_name

      # @return [String]
      attr_accessor :content

      # @return [String] description
      attr_accessor :desc

      # @return [Hash] options
      attr_accessor :opts

      ##
      # @param name (see #name=)
      # @param content [String, nil]
      # @param opts [Hash] options
      #
      def initialize(name, content = nil, opts = {})
        self.name = name
        @content = content
        @opts = opts
        @desc = nil
      end

      ##
      # @return [String] the name in format +suite_name:local_name+.
      def name
        [@suite_name, @local_name].join(NAME_SEPARATOR)
      end

      ##
      # @param name [String, Array<String>] a String in format
      #        +suite_name:local_name+, or an Array with the suite_name and the
      #        local_name.
      #
      def name=(*name)
        name.flatten!
        @suite_name, @local_name = name.one? ? name.first.split(NAME_SEPARATOR, 2) : name
      end

      ##
      # @param pattern [String] the glob pattern (e.g. `block_*:with*`).
      # @return [Boolean] +true+ if the name matches against the +pattern+,
      #         +false+ otherwise.
      #
      def name_match?(pattern)
        globs = pattern.split(NAME_SEPARATOR, 2)
        [suite_name, local_name].zip(globs).all? do |name, glob|
          File.fnmatch?(glob || '*', name.to_s)
        end
      end

      ##
      # @return [Boolean] +true+ if has non-blank content, +false+ otherwise.
      def content?
        !content.blank?
      end

      ##
      # Returns value(s) of the named option.
      #
      # @param name [#to_sym] the option name.
      # @return [Array<String>, Boolean] the option value.
      #
      def [](name)
        @opts[name.to_sym]
      end

      ##
      # Sets or unsets the option.
      #
      # @param name [#to_sym] the option name.
      # @param value [Array<String>, Boolean, String, nil] the option value;
      #        +Array+ and +Boolean+ are just assigned to the option, +nil+
      #        removes the option and others are added to the option as an
      #        array item.
      #
      def []=(name, value)
        case value
        when nil
          @opts.delete(name.to_sym)
        when Array, TrueClass, FalseClass
          @opts[name.to_sym] = value.deep_dup
        else
          (@opts[name.to_sym] ||= []) << value.dup
        end
      end

      def to_s
        content.dup
      end

      def ==(other)
        other.class == self.class && other.instance_values == self.instance_values
      end

      def initialize_copy(source)
        instance_variables.each do |name|
          instance_variable_set name, instance_variable_get(name).deep_dup
        end
      end
    end
  end
end
