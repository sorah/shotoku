module Shotoku
  class Command
    class CommandFailed < Exception; end

    def initialize(command)
      @command = command

      @waiting_threads = []
      @waiting_threads_mutex = Mutex.new
      @output_listeners = []
      @stdout_listeners = []
      @stderr_listeners = []

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

      @waiting_threads_mutex.synchronize {
        @waiting_threads << Thread.current
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

    def value
      wait
      raise exception if exception?
      unless success?
        raise CommandFailed, "Command failed (" \
                             "#{signaled? ? "signal=#{termsig} " : nil}" \
                             "#{exited? ? "status=#{exitstatus}" : nil}" \
                             "): #{script.inspect}"
      end
      success?
    end

    def on_stdout(&block)
      @stdout_listeners << block
    end

    def on_stderr(&block)
      @stderr_listeners << block
    end

    def on_output(&block)
      @output_listeners << block
    end

    def complete!(exitstatus: nil, termsig: nil, exception: nil)
      raise 'already completed (possible bug)' if completed?
      @exitstatus = exitstatus
      @termsig = termsig
      @exception = exception
      @waiting_threads_mutex.synchronize {
        r = @waiting_threads.dup
        @waiting_threads.clear
        r
      }.each(&:wakeup)
    end

    def send_handler(&block)
      @send_handler = block
    end

    def eof_handler(&block)
      @eof_handler = block
    end

    def add_stdout(string)
      @stdout += string
      @output_listeners.each { |_| _[string, :out] }
      @stdout_listeners.each { |_| _[string] }
      self
    end

    def add_stderr(string)
      @stderr += string
      @output_listeners.each { |_| _[string, :err] }
      @stderr_listeners.each { |_| _[string] }
      self
    end
  end
end
