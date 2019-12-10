require 'uri'
require 'faraday'
require 'ostruct'

#
# This class will handle the sending of protobuf message to agent using http request
#
module Stackify
  class AgentHTTPSender < AgentBaseSender

    HEADERS = {
      'Content-Type' => 'application/x-protobuf'
    }

    # send_request() This function will post an http request
    # @msgs {Object} Protobuf message
    # return {Object} Return an object {status, message}
    def send_request log_group
      begin
        # Convert data into binary and send it to agent
        message = Stackify::LogGroup.encode(log_group)
        conn = Faraday.new(proxy: Stackify.configuration.proxy, ssl: { verify: false })
        @response = conn.post do |req|
          req.url URI(Stackify.configuration.http_endpoint + Stackify.configuration.agent_log_url)
          req.headers = HEADERS
          req.body = message
        end
        if @response.try(:status) == 200
          Stackify.internal_log :debug, "[AgentHTTPSender]: Successfully send message via http request."
          return OpenStruct.new({status: 200, msg: 'OK'})
        else
          Stackify.internal_log :debug, "[AgentHTTPSender] Sending failed."
          return OpenStruct.new({status: 500, msg: 'Not OK'})
        end
      rescue => exception
        Stackify.log_internal_error "[AgentHTTPSender] send_logs() Error: #{exception}"
        return OpenStruct.new({status: 500, msg: exception})
      end
    end
  end
end
