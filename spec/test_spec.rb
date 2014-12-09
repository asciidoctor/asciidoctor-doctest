describe DocTest::Test do

  subject(:test_class) { Class.new described_class }

  let(:renderer) { double 'Renderer' }
  let(:input_suite) { double 'ExamplesSuite' }
  let(:output_suite) { double 'ExamplesSuite' }

  before do
    test_class.instance_variable_set(:@renderer, renderer)
  end

  it { is_expected.to have_method :input_suite, :output_suite, :renderer }


  describe '.define_test' do
    before { test_class.define_test('dummy') { 42 } }

    it 'defines method with the given name' do
      is_expected.to have_method :dummy
      expect(test_class.new('dummy').send(:dummy)).to eq 42
    end

    it "adds the method's name to runnable_methods" do
      expect(test_class.runnable_methods).to eq ['dummy']
    end
  end


  describe '.runnable_methods' do
    subject { test_class.runnable_methods }

    context 'when no test defined yet' do
      it { is_expected.to be_empty }
    end

    context 'when some test is defined using test macro' do
      it 'returns array with the test method name' do
        test_class.define_test('dummy') { 42 }
        is_expected.to eq ['dummy']
      end
    end

    context 'when any method named /test_.*/ exists' do
      it 'returns array with the method name' do
        test_class.send(:define_method, :test_me) { 42 }
        is_expected.to eq ['test_me']
      end
    end
  end


  describe '.generate_tests!' do

    let :examples do
      [
        [ (create_example 'bl:basic', content: '_meh_'),
          (create_example 'bl:basic', content: '<i>meh</i>') ],
        [ (create_example 'bl:noinput'),
          (create_example 'bl:noinput') ],
        [ (create_example 'bl:nooutput', content: '_meh_'),
          (create_example 'bl:nooutput') ]
      ]
    end

    before do
      expect(input_suite).to receive(:pair_with)
        .with(output_suite).and_return(examples)
      test_class.generate_tests! output_suite, input_suite
    end

    context 'when both input and output examples are present' do
      subject(:test_inst) { test_class.new('bl:basic') }

      it 'defines test method that calls method :test_example'do
        is_expected.to receive(:test_example)
        test_inst.send(:'bl:basic')
      end
    end

    context 'when input example is missing' do
      it "doesn't define a test method for it" do
        is_expected.to_not have_method :'bl:noinput'
      end
    end

    context 'when output example is missing' do
      subject { test_class.new('bl:nooutput') }

      it 'defines test method with "skip"' do
        expect { subject.send(:'bl:nooutput') }.to raise_error Minitest::Skip
      end
    end
  end


  describe '#location' do
    subject { test_class.new('block_ulist:basic').location }

    # test_class is anonymous, so we must give it some name
    before { DummyTest = test_class unless defined? DummyTest }

    it 'returns formatted example name' do
      is_expected.to eq 'DummyTest :: block_ulist : basic'
    end
  end


  describe '#test_example' do
    subject(:test_inst) { test_class.new('bl:basic') }

    let(:input_exmpl) { create_example 'bl:basic', content: '_meh_' }
    let(:output_exmpl) { create_example 'bl:basic', content: '<i>meh</i>', opts: {foo: 42} }
    let(:test_example!) { test_inst.test_example output_exmpl, input_exmpl }

    before do
      allow(input_suite).to receive(:pair_with)
        .with(output_suite)
        .and_return([])

      expect(output_suite).to receive(:convert_example)
        .with(input_exmpl, output_exmpl.opts, renderer)
        .and_return(actual_exmpl)

      test_class.generate_tests! output_suite, input_suite
    end

    context 'when examples are equivalent' do
      let(:actual_exmpl) { output_exmpl.dup }

      it 'no error is thrown' do
        expect { test_example! }.not_to raise_error
      end
    end

    context 'when examples are not equivalent' do
      let(:input_exmpl) { create_example 'bl:basic', content: '_meh_', desc: 'yada yada' }
      let(:actual_exmpl) { output_exmpl.dup.tap { |o| o.content = '<em>meh</em>' } }

      it 'throws Minitest::Assertion error' do
        expect { test_example! }.to raise_error Minitest::Assertion
      end

      context 'and input example has desc:' do
        it 'throws error which message starts with the desc' do
          expect { test_example! }.to raise_error(/^yada yada.*/)
        end
      end

      context 'and both input and output examples have desc:' do
        let(:output_exmpl) { create_example 'bl:basic', content: '<i>meh</i>', desc: 'Yoda' }

        it "throws error which message starts with the output's example desc" do
          expect { test_example! }.to raise_error(/^Yoda.*/)
        end
      end
    end
  end


  def create_example(*args)
    DocTest::BaseExample.new(*args)
  end
end
