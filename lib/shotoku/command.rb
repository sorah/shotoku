module Shotoku
  class Command
    def initialize(command)
      @command = command
      @listeners = []
      @listeners_mutex = Mutex.new
      @exitstatus, @termsig = nil, nil
      @stdout, @stderr = '', ''
      @exception = nil

      @send_handler = proc {}
      @eof_handler = proc {}
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
      !!(!exception && !termsig && exitstatus && exitstatus.zero?)
    end

    def send(*strings)
      strings.each do |str|
        @send_handler.call str
      end
    end

    def eof!
      @eof_handler.call; nil
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

    def send_handler(&block)
      @send_handler = block
    end

    def eof_handler(&block)
      @eof_handler = block
    end
  end
end
