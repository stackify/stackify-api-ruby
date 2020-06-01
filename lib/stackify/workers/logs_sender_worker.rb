module Stackify
  class LogsSenderWorker < Worker

    def initialize name = 'LogsSender worker'
      super
      case Stackify.configuration.transport
      when Stackify::DEFAULT
        name = 'LogsSender worker'
      when Stackify::UNIX_SOCKET
        name = 'UnixSocketSender worker'
      when Stackify::AGENT_HTTP
        name = 'AgentHTTPSender worker'
      end
      @name = name
      @name += " ##{self.id}"
      @type = :logs_send
    end

    def after_perform result
      if result.try(:status) == 200
        Stackify.internal_log :info, "#{@name}: Sending batch of msgs is successfully completed"
      else
        Stackify.log_internal_error "#{@name}: Sending batch of msgs is failed: #{result.try(:msg)}"
      end
    end
  end
end
