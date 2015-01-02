require 'active_support/core_ext/array/access'
require 'fileutils'
require 'forwardable'

shared_examples DocTest::BaseExamplesSuite do
  extend Forwardable

  def_delegator :suite, :create_example

  subject(:suite) { described_class.new(file_ext: '.adoc', examples_path: ex_path) }
  let(:ex_path) { ['/tmp/alpha', '/tmp/beta'] }


  describe '#initialize' do

    subject(:init) { described_class.new(args) }
    let(:args) { {} }

    {'nil' => nil, 'blank' => ' '}.each do |desc, file_ext|
      context "with file_ext #{desc}" do
        let(:args) { {file_ext: file_ext, examples_path: ex_path} }
        it { expect { init }.to raise_error ArgumentError }
      end
    end

    context 'with examples_path string' do
      let(:args) { {file_ext: '.html', examples_path: '/foo/bar'} }

      it 'wraps string to array' do
        is_expected.to have_attributes(examples_path: ['/foo/bar'])
      end
    end
  end


  describe '#parse' do
    context 'empty file' do
      subject { suite.parse '', 'block_ulist' }

      it { is_expected.to be_empty }
    end
  end


  describe '#read_examples' do
    include FakeFS::SpecHelpers

    subject(:result) { suite.read_examples group_name }

    let(:group_name) { 'section' }

    before do
      ex_path.each { |p| FileUtils.mkpath p }
      create_and_write_group ex_path.first, 'noise', '.adoc', 'foo', 'bar'

      allow(suite).to receive(:parse) do |input, group_name|
        path, file_name, *example_names = input.split("\n")
        expect(group_name).to eq file_name.split('.').first

        example_names.map do |name|
          # this content is just filling to identify the example in test
          create_example [group_name, name], content: "#{path}/#{file_name}:#{name}"
        end
      end
    end

    context "when the group's file is not found" do
      it { is_expected.to be_empty }
    end

    context "when the group's file has a wrong file extension" do
      before do
        create_and_write_group ex_path.first, group_name, '.html', 'level1', 'level2'
      end

      it { is_expected.to be_empty }
    end

    context 'when single group file is found' do
      let! :examples do
        create_and_write_group ex_path.second, group_name, '.adoc', 'level1', 'level2'
      end

      it 'returns parsed examples' do
        is_expected.to eq examples
      end
    end

    context 'when multiple group files are found and contains example with same name' do
      let! :examples do
        first = create_and_write_group ex_path.first, group_name, '.adoc', 'level1', 'level2'
        second = create_and_write_group ex_path.second, group_name, '.adoc', 'level2', 'level3'
        [*first, second[1]]
      end

      it 'returns parsed examples without duplicates (first wins)' do
        is_expected.to eq examples
      end
    end
  end


  describe '#write_examples' do
    include FakeFS::SpecHelpers

    let :examples do
      (1..2).map { |i| create_example "section:level#{i}", content: 'yada' }
    end

    before { ex_path.each { |p| FileUtils.mkpath p } }

    it 'writes serialized examples to file named after the group with file extension' do
      expect(suite).to receive :serialize do |exmpls|
        exmpls.map(&:name).join("\n")
      end
      suite.write_examples examples

      file = File.read "#{ex_path.first}/section.adoc"
      expect(file).to eq examples.map(&:name).join("\n")
    end
  end


  describe '#file_names' do
    include FakeFS::SpecHelpers

    subject(:result) { suite.group_names }

    before { ex_path.each { |p| FileUtils.mkpath p } }

    context 'when no file is found' do
      it { is_expected.to be_empty }
    end

    it 'returns names of files with matching file extension only' do
      %w[block_image.html block_ulist.adoc].each do |name|
        File.write "#{ex_path.first}/#{name}", 'yada'
      end
      is_expected.to contain_exactly 'block_ulist'
    end

    it 'returns names sorted and deduplicated' do
      (names = %w[z j d c k d]).each_with_index do |name, i|
        File.write "#{ex_path[i % 2]}/#{name}.adoc", 'yada'
      end

      is_expected.to eq names.uniq.sort
    end

    it 'ignores directories and files in subdirectories' do
      Dir.mkdir "#{ex_path.first}/invalid.adoc"
      File.write "#{ex_path.first}/invalid.adoc/wat.adoc", 'yada'

      is_expected.to be_empty
    end
  end


  describe '#update_examples' do

    let :current do
      %w[gr0:ex0 gr0:ex1 gr1:ex0 gr1:ex1].map do |name|
        create_example name, content: name.reverse
      end
    end
    let :updated do
      [ (create_example 'gr0:ex0', content: 'allons-y!'),
        (create_example 'gr1:ex1', content: 'allons-y!') ]
    end

    before do
      expect(suite).to receive(:read_examples).exactly(2).times do |group_name|
        current.select { |e| e.group_name == group_name }
      end
    end

    it 'merges current and updated examples and writes them' do
      is_expected.to receive(:write_examples).with [updated[0], current[1]]
      is_expected.to receive(:write_examples).with [current[2], updated[1]]

      suite.update_examples updated
    end
  end


  describe '#pair_with' do

    subject(:result) { ours_suite.pair_with(theirs_suite).to_a }
    let(:result_names) { result.map(&:first).map(&:name) }

    let(:ours_suite) { described_class.new(file_ext: '.xyz') }
    let(:theirs_suite) { DocTest::Asciidoc::ExamplesSuite.new(file_ext: '.adoc') }

    def ours_exmpl(suffix, group = 0)
      ours_suite.create_example "gr#{group}:ex#{suffix}", content: 'ours!'
    end

    def theirs_exmpl(suffix, group = 0)
      theirs_suite.create_example "gr#{group}:ex#{suffix}", content: 'theirs!'
    end

    before do
      expect(ours_suite).to receive(:group_names)
        .and_return(['gr0', 'gr1'])
      expect(theirs_suite).to receive(:read_examples)
        .with(/gr[0-1]/).exactly(:twice).and_return(*theirs)
      expect(ours_suite).to receive(:read_examples)
        .with(/gr[0-1]/).exactly(:twice).and_return(*ours)
    end

    context do
      let :ours do
        [ [ ours_exmpl(0, 0), ours_exmpl(1, 0) ], [ ours_exmpl(0, 1), ours_exmpl(1, 1) ] ]
      end
      let :theirs do
        [ [ theirs_exmpl(1, 0), theirs_exmpl(0, 0) ], [ theirs_exmpl(0, 1), theirs_exmpl(1, 1) ] ]
      end

      it 'returns pairs of ours/theirs examples in ours order' do
        expect(result_names).to eq %w[gr0:ex0 gr0:ex1 gr1:ex0 gr1:ex1]
        expect(result).to eq ours.flatten(1).zip theirs.flatten(1).sort_by(&:name)
      end
    end

    context 'when some example is missing' do
      let(:ours) { [(0..2).map { |i| ours_exmpl i }, []] }
      let(:theirs) { [[1, 0, 2].map { |i| theirs_exmpl i }, []] }

      context 'in theirs suite' do
        let(:theirs) { [ [theirs_exmpl(2), theirs_exmpl(0)], [] ] }

        it 'returns pairs in ours order' do
          expect(result_names).to eq %w[gr0:ex0 gr0:ex1 gr0:ex2]
        end

        it 'replaces the missing example with empty one with the name' do
          expect(result.second.last).to eq theirs_suite.create_example 'gr0:ex1'
        end
      end

      context 'in ours suite' do
        let(:ours) { [ [ours_exmpl(1), ours_exmpl(2)], [] ] }

        it 'returns pairs in ours order with the missing example at the end' do
          expect(result_names).to eq %w[gr0:ex1 gr0:ex2 gr0:ex0]
        end

        it 'replaces the missing example with empty one with the name' do
          expect(result.last.first).to eq ours_suite.create_example 'gr0:ex0'
        end
      end
    end
  end


  def create_and_write_group(path, group_name, file_ext, *examples)
    content = [path, group_name + file_ext, *examples].join("\n")
    File.write File.join(path, group_name + file_ext), content

    examples.map do |name|
      create_example [group_name, name], content: "#{path}/#{group_name}#{file_ext}:#{name}"
    end
  end
end
