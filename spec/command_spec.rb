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

    context "when completed" do
      let(:exitstatus) { nil }
      let(:termsig) { nil }

      before { subject.complete!(exitstatus: exitstatus, termsig: termsig) }

      context "with success exitstatus" do
        let(:exitstatus) { 0 }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to be_exited }
        specify { expect(subject).to_not be_signaled }
        specify { expect(subject).to be_success }
      end

      context "with failure exitstatus" do
        let(:exitstatus) { 1 }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to be_exited }
        specify { expect(subject).to_not be_signaled }
        specify { expect(subject).to_not be_success }
      end

      context "with termsig" do
        let(:termsig) { 9 }

        specify { expect(subject).to be_completed }
        specify { expect(subject).to_not be_exited }
        specify { expect(subject).to be_signaled }
        specify { expect(subject).to_not be_success }
      end
    end
  end
end
