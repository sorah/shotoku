require 'spec_helper'
require 'shotoku/command'

describe Shotoku::Command do

  subject(:command) { described_class.new('echo hi') }

  describe "#wait" do
    it "waits until it completes" do
      begin
        a = false
        th = Thread.new {
          subject.wait
          a = true
        }
        th.abort_on_exception = true

        10.times { break if th.stop?; sleep 0.1 }
        expect(th).to be_stop

        expect(a).to be_false
        subject.complete!

        th.join(2)
        expect(a).to be_true
      ensure
        th.kill if th && th.alive?
      end
    end
  end

  describe "statuses" do
    specify { expect(subject).to_not be_completed }
    specify { expect(subject).to_not be_exited }
    specify { expect(subject).to_not be_signaled }
    specify { expect(subject).to_not be_success }
    specify { expect(subject).to_not be_exception }

    context "when completed" do
      let(:exitstatus) { nil }
      let(:termsig) { nil }
      let(:exception) { nil }

      before {
        subject.complete!(exitstatus: exitstatus,
                          termsig: termsig,
                          exception: exception)
      }

      context "with success exitstatus" do
        let(:exitstatus) { 0 }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to be_exited }
        specify { expect(subject).to_not be_signaled }
        specify { expect(subject).to be_success }
        specify { expect(subject).to_not be_exception }
      end

      context "with failure exitstatus" do
        let(:exitstatus) { 1 }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to be_exited }
        specify { expect(subject).to_not be_signaled }
        specify { expect(subject).to_not be_success }
        specify { expect(subject).to_not be_exception }
      end

      context "with termsig" do
        let(:termsig) { 9 }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to_not be_exited }
        specify { expect(subject).to be_signaled }
        specify { expect(subject).to_not be_success }
        specify { expect(subject).to_not be_exception }
      end

      context "with exception" do
        let(:exception) { Exception.new }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to_not be_exited }
        specify { expect(subject).to_not be_signaled }
        specify { expect(subject).to_not be_success }
        specify { expect(subject).to be_exception }
      end
    end
  end

  describe "#value" do
    let(:exitstatus) { nil }
    let(:termsig) { nil }
    let(:exception) { nil }

    before {
      subject.complete!(exitstatus: exitstatus,
                        termsig: termsig,
                        exception: exception)
    }

    context "with exception" do
      let(:exception) { Exception.new('test') }

      specify {
        expect { subject.value }.to raise_error(exception)
      }
    end

    context "with termsig" do
      let(:termsig) { 9 }

      specify {
        expect { subject.value }.to raise_error(Shotoku::Command::CommandFailed)
      }
    end

    context "with unsuccess exitstatus" do
      let(:exitstatus) { 1 }

      specify {
        expect { subject.value }.to raise_error(Shotoku::Command::CommandFailed)
      }
    end

    context "with success exitstatus" do
      let(:exitstatus) { 0 }

      specify {
        expect { subject.value }.to_not raise_error
      }
    end
  end

  describe "#on_output" do
    it "is called when output happened" do
      buf = []
      subject.on_output { |*args| buf << args }
      expect {
        subject.add_stdout('out')
        subject.add_stderr('err')
      }.to change { buf }.from([]).to([['out', :out], ['err', :err]])
    end
  end

  describe "#on_stdout" do
    it "is called when stdout happened" do
      buf = nil
      subject.on_stdout { |arg| buf = arg }
      expect {
        subject.add_stdout('out')
      }.to change { buf }.from(nil).to('out')
    end
  end

  describe "#on_stderr" do
    it "is called when stderr happened" do
      buf = nil
      subject.on_stderr { |arg| buf = arg }
      expect {
        subject.add_stderr('out')
      }.to change { buf }.from(nil).to('out')
    end
  end

  describe "#on_complete" do
    it "is called when the execution completed" do
      flag = false
      subject.on_complete { |arg| flag = true }
      expect {
        subject.complete!(exitstatus: 0)
      }.to change { flag }.from(false).to(true)
    end
  end

  describe "#eof!" do
    it "calls handler" do
      a = false
      subject.eof_handler { a = true }
      expect { subject.eof! }.to change { a }.from(false).to(true)
    end
  end

  describe "#send" do
    it "calls handler" do
      a = nil
      subject.send_handler { |str| a = str }
      expect { subject.send('foo') }.to change { a }.from(nil).to('foo')
    end
  end

  describe "#signal_value" do
    let(:termsig) { nil }
    before { command.complete!(termsig: termsig) }
    subject { command.signal_value }

    it { should be_nil }

    context "with String" do
      let(:termsig) { 'KILL' }
      it { should eq 9 }
    end

    context "with Integer" do
      let(:termsig) { 9 }
      it { should eq 9 }
    end
  end

  describe "#signal_name" do
    let(:termsig) { nil }
    before { command.complete!(termsig: termsig) }
    subject { command.signal_name }

    it { should be_nil }

    context "with String" do
      let(:termsig) { 'KILL' }
      it { should eq 'KILL' }
    end

    context "with Integer" do
      let(:termsig) { 9 }
      it { should eq 'KILL' }
    end
  end

end
