module Stackify
  class LoggerClient
    PERIOD = 1

    def initialize
      @@errors_governor = Stackify::ErrorsGovernor.new
    end

    def log level, msg
      Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
        if acceptable? level, msg && Stackify.working?
          worker = Stackify::AddMsgWorker.new
          task = log_message_task level, msg
          worker.async_perform PERIOD, task
        end
      end
    end

    def log_exception level= :error, ex
      if ex.is_a?(Stackify::StackifiedError)
        Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
          if acceptable? level, ex.message && Stackify.working?
            if @@errors_governor.can_send? ex
              worker = Stackify::AddMsgWorker.new
              task = log_exception_task level, ex
              worker.async_perform PERIOD, task
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

    private

    def acceptable? level, msg
      Stackify.is_valid? && is_correct_log_level?(level) &&
        is_not_internal_log_message?(msg) &&
        is_appropriate_env?
    end

    def is_not_internal_log_message? msg
      msg.try(:index, ::Stackify::INTERNAL_LOG_PREFIX).nil?
    end

    def is_correct_log_level? level
      config_level = Logger.const_get Stackify.configuration.log_level.to_s.upcase
      current_level = Logger.const_get level.to_s.upcase
      current_level >= config_level
    end

    def is_appropriate_env?
      Stackify.configuration.env.downcase.to_sym == Stackify::EnvDetails.instance.auth_info['ConfiguredEnvironmentName'].downcase.to_sym
    end

    def log_message_task level, msg
      Stackify::ScheduleTask.new ({limit: 1}) do
        Stackify.msgs_queue.add_msg Stackify::MsgObject.new(level, msg, caller[0]).to_h
        str = "LoggerClient: logging of message #{msg} with level '#{level}' is completed successfully."
        Stackify.internal_log :debug, str
      end
    end

    def log_exception_task level, ex
      Stackify::ScheduleTask.new ({limit: 1}) do
        Stackify.msgs_queue.add_msg Stackify::MsgObject.new(level, ex.message, caller[0], ex).to_h
        Stackify.internal_log :debug, 'LoggerClient: '+
        'Logging of the exception %p: %s is completed successfully' % [ ex.class, ex.message ]
      end
    end
  end

end
