require 'shotoku/nodes/abstract'
require 'net/ssh'
require 'net/scp'

module Shotoku
  module Nodes
    class NetSsh < Abstract
      class ExecutionFailed < Exception; end

      def initialize(*)
        super
        @lock = Mutex.new
      end

      def connected?
        !!(@connection && !@connection.closed?)
      end

      def connect!
        disconnect! if connected?
        @lock.synchronize {
          @connection = Net::SSH.start(
            @options.delete(:host),
            @options[:user],
            @options
          )
        }
      end

      def disconnect!
        raise Shotoku::Nodes::Abstract::NotConnectedError unless connected?
        @lock.synchronize {
          @connection.close
          @connection = nil
        }
      end

      def upload(local, remote, options={})
        raise Shotoku::Nodes::Abstract::NotConnectedError unless connected?
        @lock.synchronize {
          @connection.scp.upload!(local, remote, options)
        }
      end

      def download(remote, local, options={})
        raise Shotoku::Nodes::Abstract::NotConnectedError unless connected?
        @lock.synchronize {
          @connection.scp.download!(local, remote, options)
        }
      end

      private

      def _execute(command)
        @connection.open_channel do |ch|
          ch.exec(command.script) do |ch, success|
            raise ExecutionFailed unless success

            command.send_handler do |str|
              ch.send_data str
            end

            command.eof_handler do
              ch.eof!
            end

            ch.on_data { |c, data|
              command.add_stdout data
            }
            ch.on_extended_data { |ch, type, data|
              command.add_stderr data
            }
            ch.on_request("exit-status") { |c, data|
              command.complete! exitstatus: data.content.unpack('I!>')[0]
            } 
            ch.on_request("exit-signal") { |c, data|
              command.complete! termsig: data.content.gsub(/[^a-zA-Z0-9]/,'')
            }
          end

          ch.wait
        end

        @lock.synchronize { @connection.loop }
      end
    end
  end
end


