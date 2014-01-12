require 'spec_helper'
require 'shotoku/config'

describe Shotoku::Config do
  let(:scope) { :test }
  subject(:config) { described_class.new(scope) }

  describe "#configure" do
    describe "(simple option)" do
      before do
        config.configure { simple 'test' }
      end
      subject { config.options[:simple] }

      it { should eq 'test' }
    end

    describe "(kind option)" do
      subject { config.options[:test_kind] }

      it "accepts correct kind of object" do
        config.configure { test_kind 42 }
        should eq 42
      end

      context "when give incorrect kind of object" do
        it "raises error" do
          expect {
            config.configure { test_kind 72.0 }
          }.to raise_error(ArgumentError)
        end
      end
    end

    describe "(block option)" do
      subject { config.options[:test_block].call }

      it "accepts block" do
        config.configure { test_block { :foo } }
        should eq :foo
      end

      context "when give Proc object" do
        it "accepts Proc" do
          config.configure { test_block(-> { :bar }) }
          should eq :bar
        end
      end

      context "when give non Proc object" do
        it "raises error" do
          expect {
            config.configure { test_block 72.0 }
          }.to raise_error(ArgumentError)
        end
      end
    end

    describe "(multiple option)" do
      before do
        config.configure {
          test_multiple 1
          test_multiple 2
          test_multiple 3
        }
      end

      subject { config.options[:test_multiple] }

      it "works well" do
        should eq [1,2,3]
      end
    end

    describe "(block options option)" do
      before do
        config.configure {
          test_block_options(foo: :bar) { 72 }
        }
      end

      subject { config.options[:test_block_options] }

      it "works well" do
        expect(subject[:proc].call).to eq 72
        expect(subject[:foo]).to eq :bar
      end
    end


    describe "(required option)" do
      let(:scope) { :test2 }

      context "when required option not given" do
        before do
          config.configure { }
        end

        it "raises error" do
          expect { config.validate }.to raise_error
        end
      end

      context "when required option given" do
        before do
          config.configure { test_required true }
        end

        it "raises error" do
          expect { config.validate }.to_not raise_error
        end
      end
    end

    describe "(multiple required option)" do
      let(:scope) { :test3 }

      context "when required option not given" do
        before do
          config.configure { }
        end

        it "works well" do
          expect(config.options[:test_multiple_required]).to be_empty
        end

        it "raises error" do
          expect { config.validate }.to raise_error
        end
      end

      context "when required option given" do
        before do
          config.configure { test_multiple_required true }
        end

        it "raises error" do
          expect { config.validate }.to_not raise_error
        end
      end
    end

    describe "(accepts options)" do
      before do
        config.configure {
          test_options(72, foo: :bar)
        }
      end

      subject { config.options[:test_options] }

      it "works well" do
        expect(subject[:value]).to eq 72
        expect(subject[:foo]).to eq :bar
      end

    end
  end

  describe "#load" do
    before do
      config.load "#{__dir__}/fixtures/test_config.rb"
    end

    it "loads configuration from file" do
      expect(config.options[:simple]).to eq "test"
    end
  end
end
