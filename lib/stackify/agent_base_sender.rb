require 'net_http_unix'
require 'ostruct'

#
# This class will handle the sending of protobuf message to agent
#
module Stackify
  class AgentBaseSender < Worker

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
      # @details {Object} it will return the properties based in Stackify.setup() configuration
      details = Stackify::Utils.get_app_settings
      log_group = Stackify::LogGroup.new
      msgs.each do |msg|
        log_group.logs << msg
      end
      log_group.environment = details['env']
      log_group.server_name = details['server_name']
      log_group.application_name = details['app_name']
      log_group.application_location = details['app_location']
      log_group.logger = 'Ruby logger'
      log_group.platform = 'ruby'
      log_group
    end

    def send_request log_group
      raise NotImplementedError
    end
  end
end
