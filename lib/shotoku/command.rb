module Shotoku
  class Command
    def initialize(command)
      @command = command
      @listeners = []
      @listeners_mutex = Mutex.new
      @exitstatus, @termsig = nil, nil
      @stdout, @stderr = '', ''
      @exception = nil
    end

    attr_reader :command, :exitstatus, :termsig, :stdout, :stderr, :exception

    alias script command

    def wait
      return if completed?

      @listeners_mutex.synchronize {
        @listeners << Thread.current
      }
      sleep
    end

    def completed?
      !!(termsig || exitstatus || exception)
    end

    def signaled?
      !!termsig
    end

    def exited?
      !!exitstatus
    end

    def exception?
      !!exception
    end


    def success?
      exitstatus && exitstatus.zero?
    end


    def complete!(exitstatus: nil, termsig: nil, exception: nil)
      raise 'already completed (possible bug)' if completed?
      @exitstatus = exitstatus
      @termsig = termsig
      @exception = exception
      @listeners_mutex.synchronize {
        r = @listeners.dup
        @listeners.clear
        r
      }.each(&:wakeup)
    end
  end
end
