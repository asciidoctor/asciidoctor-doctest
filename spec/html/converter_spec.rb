require 'forwardable'

module DocTest
  describe HTML::Converter do
    extend Forwardable

    def_delegator :converter, :convert_examples

    subject(:converter) { described_class.new }

    describe '#convert_examples' do

      let(:input) { Example.new 's:dummy', content: '*chunky* bacon' }
      let(:output) { Example.new 's:dummy', content: '<b>chunky</b> bacon', opts: opts }
      let(:opts) { {dummy: 'value'} }
      let(:converter_opts) { {header_footer: false} }

      subject(:result) { convert_examples input, output }

      let :rendered do
        <<-EOF
          <section>
            <h1>Title</h1>
            <div>
              <p><b>Chunky</b> bacon</p>
            </div>
            <code>meh</code>
          </section>
          <div>
            <p>why?</p>
          </div>
        EOF
      end

      before do
        expect(converter).to receive(:convert)
          .with(input.content, converter_opts).and_return(rendered)
      end

      it 'returns array of converted input content and output content'

      context 'with :exclude option' do
        let(:opts) { {exclude: ['.//p', './/code']} }

        it 'returns content without HTML (sub)elements specified by XPath' do
          expect(result.first.gsub(/\s*/, '')).to eq \
            '<section><h1>Title</h1><div></div></section><div></div>'
        end
      end

      context 'with :include option' do
        let(:opts) { {include: ['.//p']} }

        it 'returns content with only HTML (sub)elements specified by XPath' do
          expect(result.first.gsub(/\s*/, '')).to eq '<p><b>Chunky</b>bacon</p><p>why?</p>'
        end
      end

      context 'with :header_footer option' do
        let(:opts) { {header_footer: true} }
        let(:converter_opts) { {header_footer: true} }

        it 'renders content with :header_footer => true' do
          convert_examples input, output
        end
      end

      context 'with example named /^document.*/' do
        let(:input) { Example.new 'document:dummy', content: '*chunky* bacon' }
        let(:converter_opts) { {header_footer: true} }

        it 'renders content with :header_footer => true' do
          convert_examples input, output
        end
      end

      context 'with example named /inline_.*/' do
        let(:input) { Example.new 'inline_quoted:dummy', content: '*chunky* bacon' }
        let(:rendered) { '<p><b>chunky</b> bacon</p>' }

        it 'returns content without top-level <p> tags' do
          expect(result.first).to eq '<b>chunky</b> bacon'
        end

        context 'with :include option' do
          let(:opts) { {include: ['.//b']} }

          it 'preferes the include option' do
            expect(result.first).to eq '<b>chunky</b>'
          end
        end
      end
    end
  end
end
