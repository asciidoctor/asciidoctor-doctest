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
