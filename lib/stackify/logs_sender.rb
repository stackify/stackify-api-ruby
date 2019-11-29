module Stackify
  class LogsSender < HttpClient

    LOGS_URI = URI("#{Stackify.configuration.base_api_url}/Log/Save")

    def initialize
      @@errors_governor = Stackify::ErrorsGovernor.new
    end

    def log level, msg, call_trace, task
      Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
        if acceptable?(level, msg) && Stackify.working?
          worker = Stackify::AddMsgWorker.new
          worker.async_perform ScheduleDelay.new, task
        end
      end
    end

    def log_exception level= :error, ex, task
      if ex.is_a?(Stackify::StackifiedError)
        Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
          if acceptable?(level, ex.message) && Stackify.working?
            if @@errors_governor.can_send? ex
              worker = Stackify::AddMsgWorker.new
              worker.async_perform ScheduleDelay.new, task
            else
              Stackify.internal_log :warn,
              "LoggerClient: logging of exception with message \"#{ex.message}\" is skipped - flood_limit is exceeded"
            end
          end
        end
      else
        Stackify.log_internal_error 'LoggerClient: log_exception should get StackifiedError object'
      end
    end

    def has_error msg
      !msg['Ex'].nil?
    end

    def get_epoch msg
      msg['EpochMs']
    end

    def log_message_task level, msg, call_trace, trans_id=nil, log_uuid=nil
      Stackify::ScheduleTask.new ({limit: 1}) do
        if %w(error fatal).include?(level)
          ex = if ruby_exception?(msg) && msg.class != Class
            msg.set_backtrace(call_trace)
            msg
          else
            e = StringException.new(msg)
            e.set_backtrace(call_trace)
            e
          end
          ex = StackifiedError.new(ex, binding())
          Stackify.msgs_queue << Stackify::MsgObject.new(level, ex.message, caller[0], trans_id, log_uuid, ex).to_h
        else
          Stackify.msgs_queue << Stackify::MsgObject.new(level, msg, caller[0], trans_id, log_uuid).to_h
        end
      end
    end

    def log_exception_task level, ex, trans_id=nil, log_uuid=nil
      Stackify::ScheduleTask.new ({limit: 1}) do
        Stackify.msgs_queue << Stackify::MsgObject.new(level, ex.message, caller[0], trans_id, log_uuid, ex).to_h
      end
    end

    def send_logs msgs, attempts = 3
      worker = Stackify::LogsSenderWorker.new
      task = send_logs_task attempts, msgs
      worker.async_perform ScheduleDelay.new, task
    end

    private

    def acceptable? level, msg
      Stackify.is_valid? && is_correct_log_level?(level) &&
        is_not_internal_log_message?(msg)
    end

    def is_not_internal_log_message? msg
      msg.try(:index, ::Stackify::INTERNAL_LOG_PREFIX).nil?
    end

    def is_correct_log_level? level
      config_level = Logger.const_get Stackify.configuration.log_level.to_s.upcase
      current_level = Logger.const_get level.to_s.upcase
      current_level >= config_level
    end

    def ruby_exception? klass
      klass = klass.class == Class ? klass : klass.class
      klasses = [klass]
      while klass != Object do
        klasses << klass.superclass
        klass = klass.superclass
      end
      klasses.include?(Exception)
    end

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
          Stackify.internal_log :info, '[LogsSender] trying to send logs to Stackify...'
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
