require 'active_support/core_ext/array/wrap'
require 'pathname'

module Asciidoctor
  module DocTest
    ##
    # This class is responsible for parsing and serializing of examples suite
    # files. The suite file holds one or more examples written in the backend's
    # target format (e.g. HTML, TeX), or AsciiDoc in a case of the input
    # examples. Each example must be preceded by a special header with the
    # example's name and optionally a description and options.
    #
    # @abstract
    class BaseSuiteParser

      # @return [String] the filename extension (e.g. +.adoc+) of
      #   the examples suite file.
      attr_accessor :file_suffix

      # @return [String, Array<String>] path of the directory (or multiple
      #   directories) where to look for the example suites. When not
      #   specified, {DocTest.examples_path} is used as default.
      #   Relative paths are referenced from the working directory.
      attr_accessor :examples_path

      def examples_path=(path)
        @examples_path = Array.wrap(path)
      end


      ##
      # Returns a new instance of BaseSuiteParser.
      #
      # @param file_suffix [String] see {#file_suffix}.
      # @param examples_path [String, Array<String>, nil] see {#examples_path}.
      #
      def initialize(file_suffix:, examples_path: nil)
        @file_suffix = file_suffix
        self.examples_path = examples_path ? Array.wrap(examples_path) : DocTest.examples_path.dup
      end

      ##
      # Returns absolute paths of the named examples suite files found on the
      # {#examples_path}.
      #
      # @param suite_name [String] name of the suite file without a file
      #        extension (i.e. Asciidoctor's AST node name).
      # @return [Array<String>] paths of the suite files.
      #
      def find_suite_files(suite_name)
        examples_path.map { |dir_path|
          file_path = suite_path(dir_path, suite_name)
          file_path if File.file? file_path
        }.compact
      end

      ##
      # Returns names of all the example suites (files with {#file_suffix})
      # found on the {#examples_path}.
      #
      # @return [Array<String>]
      #
      def suite_names
        names = []
        examples_path.each do |dir_path|
          Dir.glob("#{dir_path}/*#{file_suffix}").each do |file_path|
            names << Pathname.new(file_path).basename.sub_ext('').to_s
          end
        end
        names.sort.uniq
      end

      ##
      # Reads the named examples suite from file(s). When multiple matching
      # files are found on the {#examples_path}, it merges them together.
      #
      # @param suite_name (see #find_suite_files)
      # @return [Array<Example>] an array of parsed examples, or an empty array
      #         if no suite found.
      #
      def read_suite(suite_name)
        find_suite_files(suite_name).map { |file_path|
          parse_suite File.read(file_path), suite_name
        }.flatten.uniq(&:name)
      end

      ##
      # Writes the given examples to a file. If the file already exists
      # on the {#examples_path}, then it overwrites the first found file.
      # Otherwise it creates a new file in the first directory from the
      # {#examples_path}.
      #
      # @param suite_name (see #find_suite_files)
      # @param examples [Array<Example>] the examples to write.
      #
      def write_suite(suite_name, examples)
        file_path = find_suite_files(suite_name).first ||
                    suite_path(examples_path.first, suite_name)
        File.open(file_path, 'w') do |file|
          file << serialize_suite(examples)
        end
      end

      ##
      # Parses an examples suite and returns it as an array of Examples.
      #
      # @abstract
      # @param input [String] the suite's content to parse.
      # @param suite_name [String] the suite name.
      # @return [Array<Example>] the parsed examples.
      #
      def parse_suite(input, suite_name)
        fail NotImplementedError
      end

      ##
      # Serializes the given array of Examples into examples suite String.
      #
      # @abstract
      # @param examples [Array<Example>]
      # @return [String]
      #
      def serialize_suite(examples)
        fail NotImplementedError
      end

      private

      def suite_path(dir_path, suite_name)
        Pathname.new(suite_name).expand_path(dir_path).sub_ext(file_suffix).to_s
      end
    end
  end
end
