require 'net_http_unix'
require 'ostruct'

#
# This class will handle the sending of protobuf message to unix domain socket
#
module Stackify
  class UnixSocketSender < AgentBaseSender

    # send_request() This function will send http request via unix domain socket
    # @msgs {Object} Protobuf message
    # return {Object} Return an object {status, message}
    def send_request log_group
      begin
        # Convert data into binary and send it to unix domain socket
        message = Stackify::LogGroup.encode(log_group)
        client = NetX::HTTPUnix.new('unix://' + Stackify.configuration.unix_socket_path)
        req = Net::HTTP::Post.new(Stackify.configuration.agent_log_url)
        req.set_content_type('application/x-protobuf')
        req.body = message
        response = client.request(req)
        Stackify.internal_log :debug, "[UnixSocketSender] status_code = #{response.code}"
        if response.code.to_i == 200
          Stackify.internal_log :debug, "[UnixSocketSender]: Successfully send message via unix domain socket."
          return OpenStruct.new({status: 200, msg: 'OK'})
        else
          Stackify.internal_log :debug, "[UnixSocketSender] Sending failed."
          return OpenStruct.new({status: 500, msg: 'Not OK'})
        end
      rescue => exception
        Stackify.log_internal_error "[UnixSocketSender] send_logs() Error: #{exception}"
        return OpenStruct.new({status: 500, msg: exception})
      end
    end
  end
end
