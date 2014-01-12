require 'spec_helper'
require 'shotoku/command'

describe Shotoku::Command do
  subject { described_class.new('echo hi') }

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
end
