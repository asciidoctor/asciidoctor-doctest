describe Enumerable do

  describe '#map_send' do

    it 'sends a message to each element and collects the result' do
      expect([1, 2, 3].map_send(:+, 3)).to eq [4, 5, 6]
    end
  end
end

describe String do

  describe '#concat' do

    context 'without separator' do
      subject { 'foo' }

      it 'appends the given string to self' do
        subject.concat 'bar'
        is_expected.to eq 'foobar'
      end
    end

    context 'with separator' do

      context 'when self is empty' do
        subject { '' }

        it 'appends the given string to self' do
          subject.concat 'bar', "\n"
          is_expected.to eq 'bar'
        end
      end

      context 'when self is not empty' do
        subject { 'foo' }

        it 'appends the given separator and string to self' do
          subject.concat 'bar', "\n"
          is_expected.to eq "foo\nbar"
        end
      end
    end
  end
end


describe Module do

  describe '#alias_class_method' do

    subject(:klass) do
      Class.new do
        def self.salute
          'Meow!'
        end
      end
    end

    it 'defines new class method that calls the old class method' do
      klass.alias_class_method :say_hello!, :salute

      expect(klass).to respond_to :say_hello!
      expect(klass.say_hello!).to eq klass.salute
    end
  end
end
