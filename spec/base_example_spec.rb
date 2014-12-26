describe DocTest::BaseExample do

  subject(:o) { described_class.new ['foo', 'bar'] }

  it { is_expected.to respond_to :group_name, :local_name, :content, :content_normalized,
                                 :content_pretty, :desc, :opts }

  describe '#name' do

    it 'returns #{group_name}:#{local_name}' do
      o.group_name = 'block_olist'
      o.local_name = 'with-start'

      expect(o.name).to eq "#{o.group_name}:#{o.local_name}"
    end
  end

  describe '#name=' do

    shared_examples :example do
      it 'sets group_name and local_name' do
        is_expected.to have_attributes group_name: 'section', local_name: 'basic'
      end
    end

    context 'with String' do
      before { o.name = 'section:basic' }
      include_examples :example
    end

    context 'with Array' do
      before { o.name = ['section', 'basic'] }
      include_examples :example
    end
  end

  describe '#name_match?' do
    name = 'block_ulist:with-title'

    context "when name is e.g. #{name}" do
      subject(:o) { described_class.new(name) }

      [ '*', '*:*', 'block_ulist:*', '*:with-title', 'block_*:*',
        'block_ulist:with-*', 'block_ulist:*title'
      ].each do |pattern|
        it "returns true for #{pattern}" do
          expect(o.name_match?(pattern)).to be_truthy
        end
      end

      [ 'block_foo:with-title', 'block_ulist:foo', 'foo:*' '*:foo', 'foo'
      ].each do |pattern|
        it "returns false for #{pattern}" do
          expect(o.name_match?(pattern)).to be_falsy
        end
      end
    end
  end

  describe '#empty?' do
    subject { o.empty? }

    context 'when content is nil' do
      before { o.content = nil }
      it { is_expected.to be_truthy }
    end

    context 'when content is blank' do
      before { o.content = ' ' }
      it { is_expected.to be_truthy }
    end

    context 'when content is not blank' do
      before { o.content = 'allons-y!' }
      it { is_expected.to be_falsy }
    end
  end

  describe '#[]' do

    context 'when option exists' do
      it 'returns the option value' do
        o.opts[:foo] = 'bar'
        expect(o['foo']).to eq 'bar'
      end
    end

    context 'when option does not exist' do
      it 'returns nil' do
        expect(o[:nothing]).to be_nil
      end
    end
  end

  describe '#[]=' do
    subject { o.opts }

    context 'with boolean value' do
      [true, false].each do |value|
        it "associates the option with #{value}" do
          o['foo'] = value
          is_expected.to eq(foo: value)
        end
      end
    end

    context 'with Array value' do
      it 'associates the option with the value' do
        o['foo'] = ['a', 'b']
        is_expected.to eq(foo: ['a', 'b'])
      end
    end

    context 'with String value' do

      context 'when option is not defined' do
        it 'associates the option with the value wrapped in an array' do
          o['key'] = 'foo'
          is_expected.to eq(key: ['foo'])
        end
      end

      context 'when option is already defined' do
        before { o.opts[:key] = ['foo'] }

        it 'adds the value to array associated with the option' do
          o[:key] = 'bar'
          is_expected.to eq(key: ['foo', 'bar'])
        end
      end
    end

    context 'with nil value' do
      before { o.opts[:key] = ['foo'] }

      it 'deletes the option' do
        o[:key] = nil
        is_expected.to be_empty
      end
    end
  end

  describe '#==' do

    let(:first) { described_class.new('a:b', content: 'allons-y!') }
    let(:second) { described_class.new('a:b', content: 'allons-y!') }

    it 'returns true for different instances with the same name and content' do
      expect(first).to eq second
    end

    it 'returns false for instances with different name' do
      second.name = 'a:x'
      expect(first).to_not eq second
    end

    it 'returns false for instances with different content_normalized' do
      expect(second).to receive(:content_normalized).and_return('ALLONS-Y!')
      expect(first).to_not eq second
    end
  end

  describe '#dup' do
    it 'returns deep copy' do
      origo = described_class.new('a:b', content: 'allons-y!', desc: 'who?', opts: {key: ['value']})
      copy = origo.dup

      expect(origo).to eql copy
      expect(origo).to_not equal copy

      origo.instance_values.values.zip(copy.instance_values.values).each do |val1, val2|
        expect(val1).to_not equal val2 unless val1.nil? && val2.nil?
      end
      expect(origo.opts[:key].first).to_not equal copy.opts[:key].first
    end
  end
end
