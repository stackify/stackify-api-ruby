module Stackify
  class ErrorsCatcher
    def initialize(app, &block)
      @app = app
      @block = block
    end

    def call(env)
      @block.call env
      @app.call env
    rescue Exception => exception
      Stackify.logger_client.log_exception(StackifiedError.new exception, binding)
      raise exception
    end

  end
end
