require 'shotoku/command'
require 'shellwords'

module Shotoku
  module Nodes
    class Abstract
      class NotConnectedError < Exception; end

      def initialize(options={})
        @options = options
      end

      def connected?
        false
      end

      def connect!
        raise NotImplementedError
      end

      def disconnect!
        raise NotImplementedError
      end

      def upload(local, remote)
        raise NotImplementedError
      end

      def download(local, remote)
        raise NotImplementedError
      end

      def read(remote)
        execute("cat #{Shellwords.escape(remote)}",
                async: false, error_on_failure: true).stdout
      end

      def write(string, remote, mode: nil, async: false)
        remote_safe = Shellwords.escape(remote)
        if mode
          execute("touch #{remote_safe} && chmod #{Shellwords.escape(mode)} #{remote_safe}",
                  async: false, error_on_failure: true)
        end

        execute("cat > #{remote_safe}", async: async, error_on_failure: !async) do |cmd|
          cmd.send(string)
          cmd.eof!
        end
      end

      def execute(cmd, within: nil, async: true, error_on_failure: false)
        unless connected?
          raise NotConnectedError
        end

        if error_on_failure && async
          raise ArgumentError, "Can't raise error in async mode"
        end

        script = <<-EOF
#{within ? "cd #{Shellwords.escape(within)}": nil}
#{cmd}
        EOF
        command = Command.new(script)
 
        th = Thread.new do
          begin
            _execute(command)
          rescue Exception => e
            command.complete!(exception: e) unless command.complete?
          end
        end

        yield command if block_given?

        command.wait unless async
        command.value if !async && error_on_failure && !command.success?

        command
      end

      private

      def _execute(command)
        raise NotImplementedError
      end
    end
  end
end
