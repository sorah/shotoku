module Shotoku
  class Command
    def initialize(command)
      @command = command
      @listeners = []
      @listeners_mutex = Mutex.new
      @exitstatus, @termsig = nil, nil
      @stdout, @stderr = '', ''
    end

    attr_reader :command, :exitstatus, :termsig, :stdout, :stderr

    alias script command

    def wait
      unless completed?
        @listeners_mutex.synchronize {
          @listeners << Thread.current
        }
        sleep
      end
    end

    def exited?
      !!exitstatus
    end

    def completed?
      !!(termsig || exitstatus)
    end

    def signaled?
      !!termsig
    end

    def success?
      exitstatus && exitstatus.zero?
    end

    def complete!(exitstatus: nil, termsig: nil)
      @exitstatus = exitstatus
      @termsig = termsig
      @listeners_mutex.synchronize {
        r = @listeners.dup
        @listeners.clear
        r
      }.each(&:wakeup)
    end
  end
end
