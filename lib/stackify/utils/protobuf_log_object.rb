module Stackify
  class ProtobufLogObject
    def initialize level, msg, caller_str, trans_id=nil, log_uuid=nil, ex=nil
      @level, @msg, @caller_str, @ex = level, msg, caller_str, ex, @trans_id = trans_id,
      @log_uuid = log_uuid
    end

    # Create a LogMsgGroup Protobuf Object
    def to_obj
      begin
        log = Stackify::LogGroup::Log.new
        log.message = @msg
        log.thread_name = Thread.current.object_id.to_s
        log.date_millis = (Time.now.to_f * 1000).to_i
        log.level = @level.to_s.upcase!
        log.source_method = Stackify::Backtrace.method_name(@caller_str).to_s
        log.source_line = Stackify::Backtrace.line_number(@caller_str).to_i
        log.transaction_id = @trans_id unless @trans_id.nil?
        log.id = @log_uuid unless @log_uuid.nil?
        if @ex.try(:to_h)
          ex = @ex.try(:to_h)
          log_error = Stackify::LogGroup::Log::Error.new
          log_error.date_millis = ex['OccurredEpochMillis'].to_i
          if ex['EnvironmentDetail']
            env = ex['EnvironmentDetail']
            env_detail = Stackify::LogGroup::Log::Error::EnvironmentDetail.new
            env_detail.device_name = env['DeviceName'].to_s
            env_detail.application_name = env['AppName'].to_s
            env_detail.application_location = env['AppLocation'].to_s
            env_detail.configured_application_name = env['ConfiguredAppName'].to_s
            env_detail.configured_environment_name = env['ConfiguredEnvironmentName'].to_s
            log_error.environment_detail = env_detail
          end
          if ex['Error']
            err = ex['Error']
            error_item = Stackify::LogGroup::Log::Error::ErrorItem.new
            error_item.message = err['Message'].to_s
            error_item.error_type = err['ErrorType'].to_s
            error_item.error_type_code = err['ErrorTypeCode'].to_s
            if err['Data']
              map_data = Google::Protobuf::Map.new(:string, :string)
              err['Data'].each { |key, value| map_data["#{key}"] = value }
              error_item.data = map_data
            end
            error_item.inner_error = err['InnerError']
            error_item.source_method = err['SourceMethod'].to_s
            if err['StackTrace']
              stack = err['StackTrace']
              stack.each do |stk|
                trace_frame = Stackify::LogGroup::Log::Error::ErrorItem::TraceFrame.new
                trace_frame.code_filename = stk['CodeFileName'].to_s
                trace_frame.line_number = stk['LineNum'].to_i
                trace_frame.method = stk['Method'].to_s
                error_item.stacktrace.push(trace_frame)
              end
            end
            log_error.error_item = error_item
          end
          if ex['WebRequestDetail']
            req_details = ex['WebRequestDetail']
            web_request = Stackify::LogGroup::Log::Error::WebRequestDetail.new
            web_request.user_ip_address = req_details['UserIPAddress'].to_s
            web_request.http_method = req_details['HttpMethod'].to_s
            web_request.request_url = req_details['RequestUrl'].to_s
            web_request.request_url_root = req_details['RequestUrlRoot'].to_s
            web_request.referral_url = req_details['ReferralUrl'].to_s
            web_request.post_data_raw = req_details['PostDataRaw'].to_s
            log_error.web_request_detail = web_request
          end
          if !ex['ServerVariables'].empty?
            map_server_vars = Google::Protobuf::Map.new(:string, :string)
            ex['ServerVariables'].each { |key, value| map_server_vars["#{key.to_s}"] = value.to_s }
            log_error.server_variables = map_server_vars
          end

          log.error = log_error
        end
        log
      rescue => exception
        Stackify.internal_log :info, "[ProtobufLogObject] Error: "
        Stackify.internal_log :info, exception
      end
    end
  end
end
