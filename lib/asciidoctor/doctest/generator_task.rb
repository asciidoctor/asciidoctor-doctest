require 'active_support/core_ext/string/strip'
require 'asciidoctor/doctest/base_generator'
require 'asciidoctor/doctest/core_ext'
require 'rake/tasklib'

module Asciidoctor
  module DocTest
    ##
    # Rake task for generating of testing examples.
    # @see BaseGenerator
    class GeneratorTask < Rake::TaskLib

      # List of values representing the +true+.
      TRUE_VALUES = [ 'yes', 'y', 'true' ]

      # @return [#to_s, nil] name of the backend to convert examples.
      attr_accessor :backend_name

      # @return (see DocTest.examples_path)
      attr_accessor :examples_path

      # @return [Boolean] whether to rewrite an already existing testing
      #   example. May be overriden with +FORCE+ variable on the command line
      #   (default: false).
      attr_accessor :force

      # @return [BaseGenerator] an instance of the generator.
      attr_accessor :generator

      # @return [#to_sym] name of the task.
      attr_accessor :name

      # @return [String] path of the directory where to write generated
      #   examples (default: +test/examples+).
      attr_accessor :output_dir

      # @return [String] glob pattern to select examples to (re)generate.
      #   May be overriden with +PATTERN+ variable on the command line
      #   (default: *:*).
      attr_accessor :pattern

      # @return [Array<String>] paths of the directories where to look for the
      #   templates (backends) (default: +data/templates+).
      attr_accessor :templates_path

      # @return [String] title of the task's description.
      attr_accessor :title


      ##
      # Returns a new instance of GeneratorTask.
      #
      # @param name [#to_sym] name of the task.
      # @param generator [BaseGenerator, Class] the generator class (or its
      #        instance). If class is given, then it's instantiated with zero
      #        arguments.
      # @yield The block to configure this task.
      #
      def initialize(name, generator)
        @name = name.to_sym
        @generator = generator.with { is_a?(Class) ? new : self }
        @backend_name = nil
        @examples_path = DocTest.examples_path
        @force = false
        @output_dir = File.join('test', 'examples')
        @pattern = BaseGenerator::ALL_PATTERN
        @templates_path = [ File.join('data', 'templates') ]
        @title = "Generate testing examples #{pattern}#{" for #{name}" if name != :generate}."

        yield self if block_given?
        define
      end

      def define
        desc description

        task name do
          generator.tap do |g|
            g.backend_name = backend_name
            g.templates_path = templates_path
            g.asciidoc_suite_parser.examples_path = examples_path
            g.tested_suite_parser.examples_path = [output_dir]
          end
          puts title
          generator.generate! pattern, force?
        end
        self
      end

      def description
        <<-EOS.strip_heredoc
          #{title}

          Options (environment variables):
            PATTERN   glob pattern to select examples to (re)generate. [default: #{@pattern}]
                      E.g. *:*, block_toc:basic, block*:*, *list:with*, ...
            FORCE     overwrite existing examples (yes/no)? [default: #{@force ? 'yes' : 'no'}]

        EOS
      end

      def pattern
        ENV['PATTERN'] || @pattern
      end

      def force?
        !!force
        TRUE_VALUES.include?(ENV['FORCE'].downcase) unless ENV.key? 'FORCE'
      end
    end
  end
end
