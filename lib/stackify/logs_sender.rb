module Stackify
  class LogsSender < HttpClient

    LOGS_URI = URI("#{Stackify.configuration.base_api_url}/Log/Save")

    def send_logs msgs, attempts = 3
      worker = Stackify::LogsSenderWorker.new
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
        failure_msg = 'LogsSender: tried to send logs'
        Stackify.if_not_authorized failure_msg do
          Stackify.internal_log :info, 'LogsSender: trying to send logs to Stackify...'
          send_request LOGS_URI, gather_and_pack_data(msgs).to_json
        end
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
  end
end
