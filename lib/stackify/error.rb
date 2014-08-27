module Stackify

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
      @exception.class
    end

    def to_h
      env = Stackify::EnvDetails.instance
      {
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
        'WebRequestDetail' => env.request_details.try{ |d| d.fetch('webrequest_details', '') },
        'ServerVariables' => env.request_details.try{ |d| d.fetch('server_variables', '') },
        'CustomerName' => 'Customer',
        'UserName' => @context.fetch('user', '')
      }
    end

  end

end
