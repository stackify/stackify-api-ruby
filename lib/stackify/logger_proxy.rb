module Stackify
  class LoggerProxy < Object

    def initialize logger
      @logger = logger
      @logger.level = Logger.const_get(Stackify.configuration.log_level.to_s.upcase)
      %w(debug info warn error fatal unknown).each do |level|
        stackify_logger = if level == 'debug'
          -> (msg, caller) { Stackify.logger_client.log(level.downcase, msg, caller) unless msg.empty? }
        else
          -> (msg, caller) { Stackify.logger_client.log(level.downcase, msg, caller) }
        end
        LoggerProxy.class_eval do
          define_method level.to_sym do |*args , &block|
            msg = message(*args, &block)
            stackify_logger.call(msg, caller)
            @logger.send(level.to_sym, msg, &block)
          end
        end
      end
    end

    protected

    def method_missing(name, *args, &block)
      @logger.send(name, *args, &block)
    end

    private

    def message *args, &block
      if block_given?
        block.call
      else
        args = args.flatten.compact
        args = (args.count == 1 ? args[0] : args)
        args.is_a?(Proc) ? args.call : args
      end
    end

  end
end
