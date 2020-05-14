module Stackify
  class StringException < StandardError
    def class
      'StringException'.freeze
    end
  end
  class StackifiedError < StandardError

    CONTEXT_PROPERTIES =  { 'user' => 'current_user'}

    attr_reader :context, :exception

    def initialize(ex, error_binding)
      @exception = ex
      @context = {}
      CONTEXT_PROPERTIES.each do |key , value|
        @context[key] = error_binding.eval(value) if error_binding.local_variable_defined?(value.to_sym)
      end
    end

    def backtrace
      Stackify::Backtrace.stacktrace @exception.backtrace
    end

    def source_method
      Stackify::Backtrace.method_name @exception.try{ |e| e.backtrace[0] }
    end

    def message
      @exception.message
    end

    def error_type
      if @exception.class.to_s == 'StringException'
        @exception.message.split(" ")[0].to_s
      else
        @exception.class
      end
    end

    def to_h
      env = Stackify::EnvDetails.instance
      data = {
        'OccurredEpochMillis' => Time.now.to_f*1000,
        'Error' => {
          'InnerError' => @exception.try(:cause),
          'StackTrace' => backtrace,
          'Message' => message,
          'ErrorType' => error_type.to_s,
          'ErrorTypeCode' => nil,
          'Data' => {},
          'SourceMethod' => source_method,
        },
        'EnvironmentDetail' => env.auth_info,
        'CustomerName' => 'Customer',
        'UserName' => @context.fetch('user', '')
      }
      web_request_details = env.request_details.try{ |d| d.fetch('webrequest_details', '') }
      if web_request_details.nil?
        data['WebRequestDetail'] = web_request_details
      end

      server_variables = env.request_details.try{ |d| d.fetch('server_variables', '') }
      if server_variables.nil?
        data['ServerVariables'] = server_variables
      end

      data
    end

  end

end
