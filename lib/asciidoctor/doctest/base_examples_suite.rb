require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/blank'
require 'asciidoctor/doctest/core_ext'
require 'pathname'

module Asciidoctor
  module DocTest
    ##
    # @abstract
    # This is a base class that should be extended for specific example
    # formats.
    class BaseExamplesSuite

      attr_reader :examples_path, :file_ext

      ##
      # @param file_ext [String] the filename extension (e.g. +.adoc+) of the
      #        examples group files. Must not be +nil+ or blank. (required)
      #
      # @param examples_path [String, Array<String>] path of the directory (or
      #        multiple directories) where to look for the examples.
      #
      def initialize(file_ext: nil, examples_path: DocTest.examples_path)
        fail ArgumentError, 'file_ext must not be blank or nil' if file_ext.blank?

        @file_ext = file_ext.strip.freeze
        @examples_path = Array(examples_path).freeze
        @examples_cache = {}
      end

      ##
      # Parses group of examples from the +input+ and returns array of the
      # parsed examples.
      #
      # @abstract
      # @param input [#each_line] the file content to parse.
      # @param group_name [String] the examples group name.
      # @return [Array<BaseExample>] parsed examples.
      # :nocov:
      def parse(input, group_name)
        fail NotImplementedError
      end
      # :nocov:

      ##
      # Serializes the given examples into string.
      #
      # @abstract
      # @param examples [Array<BaseExample>]
      # @return [String]
      # :nocov:
      def serialize(examples)
        fail NotImplementedError
      end
      # :nocov:

      ##
      # Returns a new example based on the given input example.
      # This method should render (AsciiDoc) content of the given example using
      # the preconfigured +renderer+ and eventually apply some transformations.
      #
      # XXX describe it better...
      #
      # @abstract
      # @param example [BaseExample] the input example to convert.
      # @param opts [Hash] the options to pass to a new example.
      # @param renderer [#convert]
      # @return [BaseExample]
      # :nocov:
      def convert_example(example, opts, renderer)
        fail NotImplementedError
      end
      # :nocov:

      ##
      # (see BaseExample#initialize)
      def create_example(*args)
        BaseExample.new(*args)
      end

      ##
      # Returns enumerator that yields pairs of the examples from this suite
      # and the +other_suite+ (examples with the same name) in order of this
      # suite.
      #
      # When some example is missing in this or the +other_suite+, it's
      # substituted with an empty example of the corresponding type and name.
      # In the case of missing example from this suite, the pair is placed at
      # the end of the examples group.
      #
      # @param other_suite [BaseExamplesSuite]
      # @return [Enumerator]
      #
      def pair_with(other_suite)
        Enumerator.new do |y|
          group_names.each do |group_name|
            theirs_by_name = other_suite.read_examples(group_name).index_by(&:name)

            read_examples(group_name).each do |ours|
              theirs = theirs_by_name.delete(ours.name)
              theirs ||= other_suite.create_example(ours.name)
              y.yield ours, theirs
            end

            theirs_by_name.each_value do |theirs|
              y.yield create_example(theirs.name), theirs
            end
          end
        end
      end

      ##
      # Reads the named examples group from file(s). When multiple matching
      # files are found on the {#examples_path}, it merges them together. If
      # two files defines example with the same name, then the first wins (i.e.
      # first on the {#examples_path}).
      #
      # @param group_name [String] the examples group name.
      # @return [Array<Example>] an array of parsed examples, or an empty array
      #         if no file found.
      #
      def read_examples(group_name)
        @examples_cache[group_name] ||= read_files(group_name)
          .map { |data| parse(data, group_name) }
          .flatten
          .uniq(&:name)
      end

      ##
      # Writes the given examples into file(s)
      # +{examples_path.first}/{group_name}{file_ext}+. Already existing files
      # will be overwritten!
      #
      # @param examples [Array<BaseExample>]
      #
      def write_examples(examples)
        examples.group_by(&:group_name).each do |group_name, exmpls|
          path = file_path(@examples_path.first, group_name)
          File.write(path, serialize(exmpls))
        end
      end

      ##
      # Replaces existing examples with the given ones.
      #
      # @param examples [Array<BaseExample] the updated examples.
      # @see #write_examples
      #
      def update_examples(examples)
        examples.group_by(&:group_name).each do |group, exmpls|
          # replace cached examples with the given ones and preserve original order
          updated_group = [ read_examples(group), exmpls ]
            .map_send(:index_by, &:local_name)
            .reduce(:merge)
            .values

          write_examples updated_group
          @examples_cache.delete(group)  # flush cache
        end
      end

      ##
      # Returns names of all the example groups (files with {#file_ext})
      # found on the {#examples_path}.
      #
      # @return [Array<String>]
      #
      def group_names
        @examples_path.reduce(Set.new) { |acc, path|
          acc | Pathname.new(path).each_child
            .select { |p| p.file? && p.extname == @file_ext }
            .map { |p| p.sub_ext('').basename.to_s }
        }.sort
      end

      protected

      ##
      # Converts the given options into the format used in examples file.
      #
      # @example
      #   {
      #     option1: 'value 1',
      #     option2: ['value 1', 'value 2']
      #     option3: true
      #   }
      #   V---V---V---V---V---V---V---V---V
      #   [
      #     ':option1: value 1',
      #     ':option2: value 1',
      #     ':option2: value 2',
      #     ':option3:'
      #   ]
      #
      # @param opts [Hash] options
      # @return [Array<String>] formatted options
      #
      def format_options(opts)
        opts.each_with_object([]) do |(name, vals), ary|
          Array(vals).each do |val|
            ary << (val == true ? ":#{name}:" : ":#{name}: #{val}")
          end
        end
      end

      private

      def read_files(file_name)
        @examples_path
          .map { |dir| file_path(dir, file_name) }
          .select(&:readable?)
          .map(&:read)
      end

      def file_path(base_dir, file_name)
        Pathname.new(base_dir).join(file_name).sub_ext(@file_ext)
      end
    end
  end
end
