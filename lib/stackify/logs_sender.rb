module Stackify
  class LogsSender < HttpClient

    LOGS_URI = URI("#{Stackify.configuration.base_api_url}/Log/Save")

    def start
      worker = Stackify::Worker.new 'Main sending thread'
      task = Stackify::ScheduleTask.new do
        send_logs
      end
      worker.async_perform Stackify.configuration.send_interval, task
      Stackify.internal_log :debug, 'LogsSender: main sending thread is started'
    end

    def send_remained_msgs
      if Stackify.working?
        Stackify.internal_log :warn, 'Sending of remained msgs is possible when Stackify is terminating work.'
      else
        worker = Stackify::Worker.new 'RemainedJob worker'
        task = send_all_remained_msgs_task Stackify.msgs_queue.pop_all
        worker.perform 2, task
      end
    end

    private

    def send_logs attempts = 3
      msgs = Stackify.msgs_queue.pop #it should wait until queue will get a new chunk if queque is empty
      worker = Stackify::LogsSenderWorker.new
      task = send_logs_task attempts, msgs
      worker.async_perform 5, task
    end

    def properties
      {
        success_condition: lambda { |result| result.try(:code) == '200' },
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

    def send_all_remained_msgs_task msgs
      Stackify::ScheduleTask.new properties do
        failure_msg = 'LogsSender: tried to remained send logs'
        Stackify.if_not_authorized failure_msg do
          Stackify.internal_log :info, 'LogsSender: trying to send remained logs to Stackify...'
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
