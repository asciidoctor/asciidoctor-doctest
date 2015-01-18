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

  describe '#convert_example' do

    let(:input) { create_example 's:dummy', content: '*chunky* bacon' }
    let(:opts) { {dummy: 'value'} }
    let(:renderer) { double 'AsciidocRenderer' }

    subject(:result) { suite.convert_example input, opts, renderer }

    let :rendered do
      %q{
        \begin{table}[htp]
          \begin{tabular}{| l c r |}
          \hline
          1 & 2 & 3 \\\
          4 & 5 & 6 \\\
          \hline
          \end{tabular}
          \caption{A simple table}
        \end{table}
      }.strip_heredoc
    end

    before do
      expect(renderer).to receive(:render)
        .with(input.content).and_return(rendered)
    end

    it 'returns Example with the same name as input_example' do
      expect(result.name).to eq input.name
    end

    it 'returns Example with the given opts' do
      expect(result.opts).to eq opts
    end

    context 'with :exclude option' do
      let(:opts) { {exclude: ['/\\\begin{tabular}.*\\\end{tabular}/m']} }

      it 'returns content without substrings specified by regexp' do
        expect(result.content).to eq %q{
          \begin{table}[htp]
          \caption{A simple table}
          \end{table}
        }.strip_heredoc.strip
      end
    end

    context 'with :include option' do
      let(:opts) { {include: ['/\\\begin{tabular}.*\\\end{tabular}/m']} }

      it 'returns content with only substrings specified by regexp' do
        expect(result.content).to eq %q{
          \begin{tabular}{| l c r |}
          \hline
          1 & 2 & 3 \\\
          4 & 5 & 6 \\\
          \hline
          \end{tabular}
        }.strip_heredoc.strip
      end
    end
  end
end
