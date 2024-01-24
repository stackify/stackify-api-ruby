
module Stackify
  class LoggerProxy < Object

    def initialize logger
      rails_logger  = logger
      num_level     = logger.level
      @logger       = rails_logger

      %w(debug info warn error fatal unknown).each do |level|
        stackify_logger = if level == 'debug'
          -> (msg, caller) { Stackify.logger_client.log(num_level, level.downcase, msg, caller) unless msg.to_s.empty? }
        else
          -> (msg, caller) { Stackify.logger_client.log(num_level, level.downcase, msg, caller) }
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

    def method_missing(name, *args, **kwargs, &block)
      @logger.send(name, *args, **kwargs, &block)
    end

    def respond_to_missing?(*args, **kwargs, &block)
      @logger.respond_to?(*args, **kwargs, &block)
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
