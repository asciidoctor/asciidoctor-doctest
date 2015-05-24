describe DocTest::Tester do

  subject(:tester) { described_class.new(input_suite, output_suite, converter, reporter) }

  let(:converter) { double 'converter' }
  let(:input_suite) { double 'ExamplesSuite' }
  let(:output_suite) { double 'ExamplesSuite' }
  let(:reporter) { spy 'Reporter' }
  let(:examples) { fixtures }


  describe '#initialize' do

    context "with default reporter" do
      subject(:tester) { described_class.new(input_suite, output_suite, converter, nil) }

      it { expect(tester.reporter).to be_a DocTest::TestReporter }
    end
  end


  describe '#run_tests' do

    before do |ex|
      next if ex.metadata[:skip_before]

      expect(input_suite).to receive(:pair_with)
          .with(output_suite).and_return(examples.values)
      allow(tester).to receive(:test_example)
    end

    context "with default pattern" do

      it "pairs the examples and tests all valid pairs" do
        ['ex:alpha', 'ex:beta', 'ex:nooutput'].each do |name|
          expect(tester).to receive(:test_example).with(*examples[name])
        end
        tester.run_tests
      end
    end

    context "with specific pattern" do

      it "pairs the examples and tests those matching the pattern" do
        expect(tester).to receive(:test_example).with(*examples['ex:beta'])
        tester.run_tests(pattern: 'ex:b*')
      end
    end

    it "ignores pairs with empty input example" do
      expect(tester).to_not receive(:test_example).with(*examples['ex:noinput'])
      tester.run_tests
    end

    it "calls reporter's methods in the correct order", :skip_before do
      expect(reporter).to receive(:start).ordered
      expect(input_suite).to receive(:pair_with).and_return([]).ordered
      expect(reporter).to receive(:report).ordered
      expect(reporter).to receive(:passed?).ordered

      tester.run_tests
    end
  end


  describe '#test_example' do

    subject(:failures) { tester.test_example input_exmpl, output_exmpl }

    let(:examples_pair) { examples['ex:alpha'] }
    let(:input_exmpl) { examples_pair[0] }
    let(:output_exmpl) { examples_pair[1] }
    let(:actual) { output_exmpl.content }
    let(:expected) { output_exmpl.content }

    shared_examples :example do
      it "calls reporter" do
        expect(reporter).to receive(:record)
        tester.test_example input_exmpl, output_exmpl
      end
    end

    before do |ex|
      next if ex.metadata[:skip_before]

      expect(output_suite).to receive(:convert_examples)
        .with(input_exmpl, output_exmpl, converter)
        .and_return([actual, expected])
    end


    context "when output example is empty", :skip_before do

      let(:examples_pair) { examples['ex:nooutput'] }

      it "skips the test" do
        is_expected.to contain_exactly Minitest::Skip
      end

      include_examples :example
    end

    context "when examples are equivalent" do

      it "returns no failure" do
        is_expected.to be_empty
      end

      include_examples :example
    end

    context "when examples are not equivalent" do

      let(:actual) { '<em>meh</em>' }

      it "returns failure" do
        is_expected.to include Minitest::Assertion
      end

      context "and input example has desc:" do

        it "returns failure with message that starts with the desc" do
          expect(failures.first.message).to match /^yada.*/
        end
      end

      context "and both input and output examples have desc:" do

        let(:examples_pair) { examples['ex:beta'] }

        it "returns failure with message that starts with the output's example desc" do
          expect(failures.first.message).to match /^Yoda.*/
        end
      end

      include_examples :example
    end
  end


  def fixtures
    data = {
      'ex:alpha'    => [ {content: '_alpha_', desc: 'yada'}, {content: '<i>alpha</i>'}              ],
      'ex:beta'     => [ {content: '*beta*',  desc: 'yada'}, {content: '<b>beta</b>', desc: 'Yoda'} ],
      'ex:noinput'  => [ {},                                 {content: '<del>noinput</del>'}        ],
      'ex:nooutput' => [ {content: 'nooutput'},              {}                                     ]
    }
    data = data.map { |name, tuple|
      [ name, tuple.map { |opts| DocTest::BaseExample.new(name, opts) } ]
    }
    Hash[data]
  end
end
