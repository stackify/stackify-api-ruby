module Stackify
  class UnixSocketClient

    def initialize
      Stackify.internal_log :info, '[UnixSocketClient]: initialize()'
      @@errors_governor = Stackify::ErrorsGovernor.new
      @@sender = Stackify::UnixSocketSender.new
    end

    def log level, msg, call_trace, task
      if acceptable?(level, msg) && Stackify.working?
        worker = Stackify::AddMsgWorker.new
        worker.async_perform ScheduleDelay.new, task
      end
    end

    def log_exception level= :error, ex, task
      if ex.is_a?(Stackify::StackifiedError)
        if acceptable?(level, ex.message) && Stackify.working?
          if @@errors_governor.can_send? ex
            worker = Stackify::AddMsgWorker.new
            # task = log_exception_task level, ex
            worker.async_perform ScheduleDelay.new, task
          else
            Stackify.internal_log :warn,
            "UnixSocketClient: logging of exception with message \"#{ex.message}\" is skipped - flood_limit is exceeded"
          end
        end
      else
        Stackify.log_internal_error 'UnixSocketClient: log_exception should get StackifiedError object'
      end
    end

    def has_error msg
      !msg.error.nil?
    end

    def get_epoch msg
      msg.date_millis
    end

    def send_logs msgs, attempts = 3
      @@sender.send_logs msgs, attempts
    end

    def log_message_task level, msg, call_trace, trans_id=nil, log_uuid=nil
      File.open("./MYLOG-log_message_task.txt", 'a') { |file|
        file.puts ' '
        file.puts 'socket_client log_message_task()'
        file.puts "level = #{level}"
        file.puts "msg = #{msg}"
        file.puts "trans_id = #{trans_id}"
        file.puts "log_uuid = #{log_uuid}"
      }
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
          Stackify.msgs_queue << Stackify::ProtobufLogObject.new(level, ex.message, caller[0], trans_id, log_uuid, ex).to_obj
        else
          Stackify.msgs_queue << Stackify::ProtobufLogObject.new(level, msg, caller[0], trans_id, log_uuid).to_obj
        end
      end
    end

    def log_exception_task level, ex, trans_id=nil, log_uuid=nil
      Stackify::ScheduleTask.new ({limit: 1}) do
        Stackify.msgs_queue << Stackify::ProtobufLogObject.new(level, ex.message, caller[0], trans_id, log_uuid, ex).to_obj
      end
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
  end
end
