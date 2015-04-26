require 'fileutils'

describe DocTest::AsciidocConverter do

  subject { described_class }

  it { is_expected.to have_method :convert, :call }


  describe '#initialize' do

    context 'with defaults' do
      subject { described_class.new.opts }
      it { is_expected.to include safe: :safe }
    end

    context 'with backend_name' do
      subject { described_class.new(backend_name: 'html5').opts }
      it { is_expected.to include backend: 'html5' }

      context 'empty string' do
        subject { described_class.new(backend_name: '').opts }
        it { is_expected.to_not include :backend }
      end
    end

    context 'with template_dirs' do
      include FakeFS::SpecHelpers

      subject { described_class.new(template_dirs: template_dirs).opts }
      let(:template_dirs) { ['/tmp/html5'] }

      before { FileUtils.mkpath template_dirs[0] }

      context 'that exists' do
        it do
          is_expected.to include(
            template_dirs: template_dirs,
            converter: DocTest::NoFallbackTemplateConverter
          )
        end

        context 'and templates_fallback is true' do
          subject { described_class.new(template_dirs: template_dirs, templates_fallback: true).opts }
          it { is_expected.to include template_dirs: template_dirs }
          it { is_expected.to_not include :converter }
        end

        context 'and custom converter' do
          subject { described_class.new(template_dirs: template_dirs, converter: converter).opts }
          let(:converter) { Asciidoctor::Converter::TemplateConverter }

          it { is_expected.to include template_dirs: template_dirs, converter: converter }
        end
      end

      context "that doesn't exist" do
        let(:template_dirs) { ['/tmp/html5', '/tmp/revealjs'] }

        it { expect { subject }.to raise_error ArgumentError }
      end
    end
  end
end


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
