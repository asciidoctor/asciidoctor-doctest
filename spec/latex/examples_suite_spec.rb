require 'forwardable'

using Corefines::String::unindent

describe DocTest::Latex::ExamplesSuite do
  extend Forwardable

  it_should_behave_like DocTest::BaseExamplesSuite

  def_delegator :suite, :create_example

  subject(:suite) { described_class.new }


  describe '#initialize' do

    it 'uses ".tex" as default file_ext' do
      expect(suite.file_ext).to eq '.tex'
    end
  end


  describe 'parsing/serialization:' do

    context 'one example' do

      shared_examples :example do
        let(:parsed) { suite.parse input, 's' }
        let(:serialized) { suite.serialize output }

        it { expect(parsed).to have(1).items }

        it 'returns an array with parsed example object' do
          expect(parsed.first).to eql output
        end

        it 'returns a serialized example as string' do
          expect(serialized).to eql input
        end
      end

      context 'with name only' do
        let(:input) { "%== .basic ==%\n" }
        let(:output) { create_example 's:basic' }

        include_examples :example
      end

      context 'with multiline content' do
        let :content do
          <<-EOF.unindent
            Paragraphs don't require
            any special markup.

            To begin a new one, separate it by blank line.
          EOF
        end

        let(:input) { "%== .multiline ==%\n#{content}" }
        let(:output) { create_example 's:multiline', content: content.chomp }

        include_examples :example
      end

      context 'with description' do
        let :input do
          <<-EOF.strip_heredoc
            %== .strong
            % This is a description,
            % see?
            %==
            \\textbf{allons-y!}
          EOF
        end

        let :output do
          create_example 's:strong', content: '\\textbf{allons-y!}',
            desc: "This is a description,\nsee?"
        end

        include_examples :example
      end

      context 'with options' do
        let :input do
          <<-EOF.strip_heredoc
            %== .basic
            % :exclude: .//code
            % :exclude: .//section
            % :include: ./p/node()
            % :header_footer:
            %==
            dummy
          EOF
        end

        let :output do
          create_example 's:basic', content: 'dummy', opts: {
            exclude: ['.//code', './/section'],
            include: ['./p/node()'],
            header_footer: true
          }
        end

        include_examples :example
      end

      context 'with description and options' do
        let :input do
          <<-EOF.strip_heredoc
            %== .basic
            % This is a description.
            % :exclude: .//code
            %==
          EOF
        end

        let :output do
          create_example 's:basic', desc: 'This is a description.', opts: {
            exclude: ['.//code']
          }
        end

        include_examples :example
      end
    end

    context 'multiple examples' do
      let :input do
        <<-EOF.strip_heredoc
          %== .basic ==%
          http://asciidoctor.org

          %== .xref ==%
          Refer to <<section-a>>.
        EOF
      end

      subject(:parsed) { suite.parse input, 's' }

      it { is_expected.to have(2).items }

      it 'returns an array with parsed Example objects' do
        expect(parsed[0]).to eql create_example('s:basic', content: 'http://asciidoctor.org')
        expect(parsed[1]).to eql create_example('s:xref', content: 'Refer to <<section-a>>.')
      end
    end
  end
end
