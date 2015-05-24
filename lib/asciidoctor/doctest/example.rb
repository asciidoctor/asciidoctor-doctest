require 'corefines'

using Corefines::Object[:blank?, :deep_dup, :instance_values]

module Asciidoctor
  module DocTest
    ##
    # This class represents a single test example.
    class Example

      NAME_SEPARATOR = ':'

      # @return [String] the first part of the name.
      attr_accessor :group_name

      # @return [String] the second part of the name.
      attr_accessor :local_name

      # @return [String] raw content.
      attr_accessor :content

      # @return [String] description.
      attr_accessor :desc

      # @return [Hash] options.
      attr_accessor :opts

      ##
      # @param name (see #name=)
      # @param content [String]
      # @param desc [String] description
      # @param opts [Hash] options
      #
      def initialize(name, content: '', desc: '', opts: {})
        self.name = name
        @content = content
        @desc = desc
        @opts = opts
      end

      ##
      # @return [String] the name in format +group_name:local_name+.
      def name
        [@group_name, @local_name].join(NAME_SEPARATOR)
      end

      ##
      # @param name [String, Array<String>] a String in format
      #        +group_name:local_name+, or an Array with the group_name and the
      #        local_name.
      def name=(*name)
        name.flatten!
        @group_name, @local_name = name.one? ? name.first.split(NAME_SEPARATOR, 2) : name
      end

      ##
      # @param pattern [String] the glob pattern (e.g. +block_*:with*+).
      # @return [Boolean] +true+ if the name matches against the +pattern+,
      #         +false+ otherwise.
      def name_match?(pattern)
        globs = pattern.split(NAME_SEPARATOR, 2)
        [group_name, local_name].zip(globs).all? do |name, glob|
          File.fnmatch? glob || '*', name.to_s
        end
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

      ##
      # @return [Boolean] +true+ when the content is blank, +false+ otherwise.
      def empty?
        content.blank?
      end

      ##
      # @return [String] a copy of the content.
      def to_s
        content.dup
      end

      ##
      # @param other the object to compare with.
      # @return [Boolean] +true+ if +self+ and +other+ equals in attributes
      #         +group_name+, +local_name+ and +content+ (compared using +==+),
      #         otherwise +false+.
      def ==(other)
        [:group_name, :local_name, :content].all? do |name|
          other.respond_to?(name) &&
            public_send(name) == other.public_send(name)
        end
      end

      ##
      # @param other [Object] the object to compare with.
      # @return [Boolean] +true+ if +self+ and +other+ are instances of the same
      #         class and all their attributes are equal (compared using +==+),
      #         otherwise +false+.
      def eql?(other)
        self.class == other.class &&
          instance_values == other.instance_values
      end

      # :nocov:
      def hash
        self.class.hash ^ instance_values.hash
      end
      # :nocov:

      private

      def initialize_copy(source)
        instance_variables.each do |name|
          instance_variable_set name, instance_variable_get(name).deep_dup
        end
      end
    end
  end
end
