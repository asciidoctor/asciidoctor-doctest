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

      attr_accessor :backend_name, :examples_path, :file_suffix

      ##
      # @param backend_name [String] name of the tested Asciidoctor backend.
      #        Defaults to this class name in lowercase without +SuiteParser+
      #        suffix.
      #
      # @param file_suffix [String] the filename extension of the suite files
      #        on {#examples_path}. The default value may be specified with
      #        a class constant +FILE_SUFFIX+. If not defined, +backend_name+
      #        will be used instead.
      #
      # @param examples_path [String, Array<String>] path of the directory (or
      #        multiple directories) where to look for the example suites.
      #        When not specified, {DocTest.examples_path} is used. Relative
      #        paths are referenced from the working directory.
      #
      def initialize(backend_name: nil, file_suffix: nil, examples_path: nil)
        backend_name  ||= self.class.name.split('::').last.sub('SuiteParser', '').downcase
        @backend_name  = backend_name.to_s

        @examples_path = examples_path ? Array.wrap(examples_path) : DocTest.examples_path.dup

        file_suffix   ||= file_suffix || self.class::FILE_SUFFIX rescue @backend_name
        @file_suffix   = file_suffix.start_with?('.') ? file_suffix : '.' + file_suffix
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
        @examples_path.map { |dir_path|
          file_path = suite_path(dir_path, suite_name)
          file_path if File.file? file_path
        }.compact
      end

      ##
      # Returns names of all the example suites found on the {#examples_path},
      # i.e. files with {#file_suffix}.
      #
      # @return [Array<String>]
      #
      def suite_names
        names = []
        @examples_path.each do |dir_path|
          Dir.glob("#{dir_path}/*#{file_suffix}").each do |file_path|
            names << Pathname.new(file_path).basename.sub_ext('').to_s
          end
        end
        names.sort.uniq
      end

      ##
      # Returns a hash with the examples that matches the +pattern+.
      #
      # @example
      #   filter_examples '*list*:basic*'
      #   => { block_colist: [ :basic ],
      #        listing:      [ :basic, :basic-nowrap, ... ],
      #        block_dlist:  [ :basic, :basic-block, ... ], ... }
      #
      # @param pattern [String] the glob pattern to filter examples.
      # @return [Hash<Symbol, Array<Symbol>>]
      #
      def filter_examples(pattern)
        suite_glob, exmpl_glob = pattern.split(':')
        exmpl_glob ||= '*'
        results = {}

        suite_names.select { |suite_name|
          File.fnmatch(suite_glob, suite_name)

        }.each do |suite_name|
          suite = read_suite(suite_name)

          suite.keys.select { |exmpl_name|
            File.fnmatch(exmpl_glob, exmpl_name.to_s)
          }.each do |exmpl_name|
            (results[suite_name] ||= []) << exmpl_name
          end
        end

        results
      end

      ##
      # Reads the named examples suite from file(s). When multiple matching
      # files are found on the {#examples_path}, it merges them together.
      #
      # @param suite_name (see #find_suite_files)
      # @return [Hash] a parsed examples suite data ({#parse_suite format}),
      #         or an empty hash when no one exists.
      #
      def read_suite(suite_name)
        find_suite_files(suite_name).reverse.inject({}) do |memo, file_path|
          memo.merge! parse_suite(File.read(file_path))
        end
      end

      ##
      # Writes the given examples suite to a file. If the file already exists
      # on the {#examples_path}, then it overwrites the first found file.
      # Otherwise it creates a new file in the first directory from the
      # {#examples_path}.
      #
      # @param suite_name (see #find_suite_files)
      # @param data [Hash] the {#parse_suite examples suite}.
      #
      def write_suite(suite_name, data)
        file_path = find_suite_files(suite_name).first ||
                    suite_path(@examples_path.first, suite_name)
        File.open(file_path, 'w') do |file|
          file << serialize_suite(data)
        end
      end

      ##
      # Parses an examples suite and returns it as a hash.
      #
      # @example
      #   { :heading-h1 => { :content => "= Title" },
      #     :heading-h2 => { :content => "== Title", :include => ["//body"] } }
      #
      # @abstract
      # @param input [String] the suite's content to parse.
      # @return [Hash] the parsed examples suite.
      #
      def parse_suite(input)
        fail NotImplementedError
      end

      ##
      # Serializes the given examples suite into String.
      #
      # @abstract
      # @param suite_hash [Hash] the {#parse_suite examples suite}.
      # @return [String]
      #
      def serialize_suite(suite_hash)
        fail NotImplementedError
      end

      private

      def suite_path(dir_path, suite_name)
        Pathname.new(suite_name).expand_path(dir_path).sub_ext(file_suffix).to_s
      end
    end
  end
end
