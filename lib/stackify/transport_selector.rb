module Stackify
  class TransportSelector

    attr_reader :transport

    def initialize type
      case type
      when Stackify::DEFAULT
        @transport = Stackify::LogsSender.new
      when Stackify::UNIX_SOCKET, Stackify::AGENT_HTTP
        @transport = Stackify::AgentClient.new
      end
    end
  end
end
