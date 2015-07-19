require 'ostruct'

describe DocTest::Factory do

  subject(:factory) { Module.new { extend DocTest::Factory } }

  let(:default_opts) { {} }

  before do
    factory.register(:foo, OpenStruct, default_opts)
    factory.register(:bar, String, 'illegal')
    factory.register(:baz, Fixnum)
  end

  describe '.create' do
    it "returns instance of registered class" do
      expect( factory.create(:foo) ).to eq OpenStruct.new
    end

    context "with opts" do
      it "initializes class with opts" do
        expect( factory.create(:foo, a: 42) ).to eq OpenStruct.new(a: 42)
      end

      context "when class with default_opts" do
        let(:default_opts) { {a: 1, b: 2} }

        it "initializes class with opts merged with default_opts" do
          expect( factory.create(:foo, b: 6) ).to eq OpenStruct.new(a: 1, b: 6)
        end
      end
    end

    context "when class with default_opts" do
      let(:default_opts) { {a: 1, b: 2} }

      it "initializes class with default_opts" do
        expect( factory.create(:foo) ).to eq OpenStruct.new(default_opts)
      end
    end

    context "with unregistered name" do
      it { expect { factory.create(:unknown) }.to raise_error(ArgumentError) }
    end
  end
end
