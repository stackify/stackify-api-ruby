module Stackify
  class LoggerProxy < Object

    def initialize logger
      @logger = logger
      @logger.level = Logger.const_get(Stackify.configuration.log_level.to_s.upcase)
      %w( debug info warn error fatal unknown).each do |level|
        LoggerProxy.class_eval do
          define_method level.to_sym do |*args , &block|
            msg = message(args, block)
            Stackify.logger_client.log(level.downcase, msg)
            @logger.send(level.to_sym, args, &block)
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
      if block
        block.call
      else
        args.flatten[0]
      end
    end

  end
end
