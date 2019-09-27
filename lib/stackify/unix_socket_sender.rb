require 'net_http_unix'
require 'ostruct'

#
# This class will handle the sending of protobuf message to unix domain socket
#
module Stackify
  class UnixSocketSender < Worker

    # send_logs() Function to put the msg in the Worker
    def send_logs msgs, attempts = 3
      worker = Stackify::LogsSenderWorker.new('UnixSocketSender worker')
      task = send_logs_task attempts, msgs
      worker.async_perform ScheduleDelay.new, task
    end

    private

    def properties
      {
        success_condition: lambda { |result| result.try(:status) == 200 },
        limit: 1
      }.dup
    end

    def send_logs_task attempts = nil, msgs
      properties[:attempts] = attempts if attempts
      Stackify::ScheduleTask.new properties do
        data = create_log_group msgs
        send_request data
      end
    end

    # create_log_group() This function will create a log group protobuf object
    # @msgs {Object} Protobuf message
    # return {Object} Return an object
    def create_log_group msgs
      details = Stackify::EnvDetails.instance.set_rails_info
      log_group = Stackify::LogGroup.new
      msgs.each do |msg|
        log_group.logs << msg
      end
      log_group.environment = details['ConfiguredEnvironmentName']
      log_group.server_name = details['DeviceName']
      log_group.application_name = details['AppName']
      log_group.application_location = details['AppLocation']
      log_group.logger = 'Rails logger'
      log_group.platform = 'ruby'
      log_group
    end

    # send_request() This function will send http request via unix domain socket
    # @msgs {Object} Protobuf message
    # return {Object} Return an object {status, message}
    def send_request log_group
      begin
        # log_group = create_log_group msgs
        # Convert data into binary and send it to unix domain socket
        message = Stackify::LogGroup.encode(log_group)
        client = NetX::HTTPUnix.new('unix://' + Stackify.configuration.unix_socket_path)
        req = Net::HTTP::Post.new(Stackify.configuration.unix_socket_url)
        req.set_content_type('application/x-protobuf')
        req.body = message
        response = client.request(req)
        puts "code = #{response.code}"
        if response.code.to_i == 200
          Stackify.internal_log :debug, "[UnixSocketSender]: Successfully send message via unix domain socket."
          return OpenStruct.new({status: 200, message: 'OK'})
        else
          Stackify.internal_log :debug, "[UnixSocketSender] Sending failed."
          return OpenStruct.new({status: 500, message: 'Not OK'})
        end
      rescue => exception
        Stackify.log_internal_error "[UnixSocketSender] send_logs() Error: #{exception}"
      end
    end
  end
end
