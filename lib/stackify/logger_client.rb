module Stackify
  class LoggerClient

    def initialize
      begin
        @@errors_governor = Stackify::ErrorsGovernor.new
        @@transport = Stackify::TransportSelector.new(Stackify.configuration.transport).transport
        Stackify.internal_log :info, "[LoggerClient] initialize: #{@@transport}"
        return if @@transport.nil?
      rescue => ex
        Stackify.log_internal_error "[LoggerClient] initialize exception = #{ex.inspect}"
      end
    end

    # This function is responsible in displaying log messages based on the level criteria
    # @param num_level [Integer]  level of the clients Rails.logger
    # @param level [String]       level coming from array of levels(debug info warn error fatal unknown) that we are going to filter with num_level
    #                             So we filter all logs from num_level up to this level
    # @param msg [Integer]        log messages
    # @param call_trace [Object]  return the current execution stack
    def log num_level, level, msg, call_trace
      display_log = true
      log_appender = false
      buffer_log = false
      if defined? Rails
        display_log = false if Stackify.configuration.stdout_output
        log_appender = true if defined?(Logging)
        buffer_log = true if Stackify.configuration.buffered_logger
        unless buffer_log
          if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('4.0')
            if display_log && log_appender
              puts msg if num_level <= Logger.const_get(level.upcase).to_i
            elsif display_log && log_appender == false
              puts msg if num_level <= Logger.const_get(level.upcase).to_i
            end
          end
        end
      else
        puts msg if num_level <= Logger.const_get(level.upcase).to_i
      end

      return if @@transport.nil?
      task = log_message_task level, msg, call_trace
      @@transport.log level, msg, call_trace, task
    end

    def log_exception level= :error, ex
      return if @@transport.nil?
      task = log_exception_task level, ex
      @@transport.log_exception level, ex, task
    end

    def get_transport
      return if @@transport.nil?
      @@transport
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

    def log_message_task level, msg, call_trace, trans_id=nil, log_uuid=nil
      return if @@transport.nil?
      @@transport.log_message_task level, msg, call_trace, trans_id, log_uuid
    end

    def log_exception_task level, ex, trans_id=nil, log_uuid=nil
      return if @@transport.nil?
      @@transport.log_exception_task level, ex, trans_id, log_uuid
    end
  end
end
