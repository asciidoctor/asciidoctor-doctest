require 'fileutils'

describe DocTest::AsciidocRenderer do

  subject { described_class }

  it { is_expected.to have_method :convert, :render }


  describe '#initialize' do

    context 'with defaults' do
      subject { described_class.new }
      it { is_expected.to have_attributes backend_name: '', converter: nil, template_dirs: nil }
    end

    context 'with backend_name' do
      subject { described_class.new(backend_name: 'html5') }
      it { is_expected.to have_attributes backend_name: 'html5' }
    end

    context 'with template_dirs' do
      include FakeFS::SpecHelpers

      subject { described_class.new(template_dirs: template_dirs) }
      let(:template_dirs) { ['/tmp/html5'] }

      before { FileUtils.mkpath template_dirs[0] }

      context 'that exists' do
        it { is_expected.to have_attributes template_dirs: template_dirs,
                                            converter: DocTest::TemplateConverterAdapter }

        context 'and templates_fallback = true' do
          subject { described_class.new(template_dirs: template_dirs, templates_fallback: true) }
          it { is_expected.to have_attributes template_dirs: template_dirs, converter: nil }
        end

        context 'and custom converter' do
          subject { described_class.new(template_dirs: template_dirs, converter: converter) }
          let(:converter) { Asciidoctor::Converter::TemplateConverter }

          it { is_expected.to have_attributes template_dirs: template_dirs, converter: converter }
        end
      end

      context "that doesn't exist" do
        let(:template_dirs) { ['/tmp/html5', '/tmp/revealjs'] }

        it { expect { subject }.to raise_error ArgumentError }
      end
    end
  end
end
