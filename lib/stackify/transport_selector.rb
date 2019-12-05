module Stackify
  class TransportSelector

    attr_reader :transport

    def initialize type
      case type
      when Stackify::DEFAULT
        Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
          @transport = Stackify::LogsSender.new
        end
      when Stackify::UNIX_SOCKET, Stackify::AGENT_HTTP
        @transport = Stackify::AgentClient.new
      end
    end
  end
end
