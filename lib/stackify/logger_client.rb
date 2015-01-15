module Stackify
  class LoggerClient

    def initialize
      @@errors_governor = Stackify::ErrorsGovernor.new
    end

    def log level, msg, call_trace
      Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
        if acceptable? level, msg && Stackify.working?
          worker = Stackify::AddMsgWorker.new
          task = log_message_task level, msg, call_trace
          worker.async_perform ScheduleDelay.new, task
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

    def log_message_task level, msg, call_trace
      Stackify::ScheduleTask.new ({limit: 1}) do
        e = Exception.new(msg)
        e.set_backtrace(call_trace)
        ex = StackifiedError.new(e, binding())
        Stackify.msgs_queue << Stackify::MsgObject.new(level, ex.message, caller[0], ex).to_h
      end
    end

    def log_exception_task level, ex
      Stackify::ScheduleTask.new ({limit: 1}) do
        Stackify.msgs_queue << Stackify::MsgObject.new(level, ex.message, caller[0], ex).to_h
      end
    end
  end

end
