#
# This class will handle the sending of log group message to agent
#
module Stackify
  class AgentBaseSender < Worker

    # send_logs() Function to put the msg in the Worker
    def send_logs msgs, attempts = 3
      case Stackify.configuration.transport
      when Stackify::DEFAULT
        name = 'LogsSender worker'
      when Stackify::UNIX_SOCKET
        name = 'UnixSocketSender worker'
      when Stackify::AGENT_HTTP
        name = 'AgentHTTPSender worker'
      end
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
        data = gather_and_pack_data(msgs).to_json
        send_request data
      end
    end

    def gather_and_pack_data msgs
      details = Stackify::EnvDetails.instance.auth_info
      {
        'CDID' => details['DeviceID'],
        'CDAppID' => details['DeviceAppID'],
        'Logger' => 'Rails logger',
        'AppName' => details['AppName'],
        'AppNameID' => details['AppNameID'],
        'Env' => details['Env'],
        'EnvID' => details['EnvID'],
        'AppEnvID' => details['AppEnvID'],
        'ServerName' => details['DeviceName'],
        'Msgs' => msgs,
        'AppLoc' => details['AppLocation'],
        'Platform' => 'Ruby'
      }
    end

    def send_request log_group
      raise NotImplementedError
    end
  end
end
