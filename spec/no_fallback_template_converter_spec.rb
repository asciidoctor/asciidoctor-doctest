describe DocTest::NoFallbackTemplateConverter do

  subject(:delegator) { described_class.new('html5', template_dirs: ['/tmp/html5']) }

  describe '#convert' do

    let(:converter) { delegator.__getobj__ }
    let(:node) { double('Node', node_name: 'block_foo') }

    before do
      expect(converter).to receive(:handles?).with('block_foo').and_return(handles)
    end

    context 'when template is not found' do
      let(:handles) { false }

      it 'returns a not found marker instead of converted node' do
        expect(converter).to_not receive(:convert)
        expect(delegator.convert node).to eq described_class::NOT_FOUND_MARKER
      end

      it 'prints a warning on stderr' do
        expect { delegator.convert node }.to output(/Could not find a custom template/i).to_stderr
      end
    end

    context 'when template is found' do
      let(:handles) { true }

      it 'delegates to the original #convert and returns result' do
        expect(converter).to receive(:convert)
          .with(node, 'block_foo', {}).and_return('allons-y!')

        expect(delegator.convert node).to eq 'allons-y!'
      end
    end
  end
end
