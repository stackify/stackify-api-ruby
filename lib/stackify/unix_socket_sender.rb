require 'net_http_unix'

module Stackify
  class UnixSocketSender

    def send_logs msgs, attempts = 3
      begin
        details = Stackify::EnvDetails.instance.set_rails_info
        log_group = Stackify::LogGroup.new
        msgs.each do |msg|
          date_millis = msg['EpochMs'].to_i
          log = Stackify::LogGroup::Log.new
          log.message = msg['Msg'].to_s
          log.thread_name = msg['Th'].to_s
          log.date_millis = date_millis
          log.level = msg['Level'].to_s
          log.source_method = msg['SrcMethod'].to_s
          log.source_line = msg['SrcLine'].to_i
          log.transaction_id = msg['TransID'].to_s
          log.id = msg['id'].to_s

          if msg['Ex']
            ex = msg['Ex']
            if ex['EnvironmentDetail']
              env = ex['EnvironmentDetail']
              env_detail = Stackify::LogGroup::Log::Error::EnvironmentDetail.new(device_name: env['DeviceName'].to_s,
                                                                                 application_name: env['AppName'].to_s,
                                                                                 application_location: env['AppLocation'].to_s,
                                                                                 configured_application_name: env['ConfiguredAppName'].to_s,
                                                                                 configured_environment_name: env['ConfiguredEnvironmentName'].to_s)
            end

            if ex['Error']
              err = ex['Error']
              date_millis = ex['OccurredEpochMillis']
              log_error = Stackify::LogGroup::Log::Error.new
              log_error.environment_detail = env_detail
              log_error.date_millis = date_millis.to_i
              error_item = Stackify::LogGroup::Log::Error::ErrorItem.new(message: err['Message'].to_s,
                                                                         error_type: err['ErrorType'].to_s,
                                                                         error_type_code: err['ErrorTypeCode'].to_s,
                                                                         data: err['Data'],
                                                                         inner_error: err['InnerError'],
                                                                         source_method: err['SourceMethod'].to_s)
              if err['StackTrace']
                stack = err['StackTrace']
                stack.each do |stk|
                  trace_frame = Stackify::LogGroup::Log::Error::ErrorItem::TraceFrame.new(code_filename: stk['CodeFileName'].to_s,
                                                                                          line_number: stk['LineNum'].to_i,
                                                                                          method: stk['Method'].to_s)
                  error_item.stacktrace.push(trace_frame)
                end
              end
            end

            if ex['WebRequestDetail']
              req_details = ex['WebRequestDetail']
              web_request = Stackify::LogGroup::Log::Error::WebRequestDetail.new(user_ip_address: req_details['UserIPAddress'].to_s,
                                                                                 http_method: req_details['HttpMethod'].to_s,
                                                                                 request_url: req_details['RequestUrl'].to_s,
                                                                                 request_url_root: req_details['RequestUrlRoot'].to_s,
                                                                                 post_data_raw: req_details['PostDataRaw'].to_s)
              log_error.web_request_detail = web_request
            end
          end

          log_group.logs << log
        end
        log_group.environment = details['ConfiguredEnvironmentName']
        log_group.server_name = details['DeviceName']
        log_group.application_name = details['AppName']
        log_group.application_location = details['AppLocation']
        log_group.logger = 'Rails logger'
        log_group.platform = 'ruby'
        message = Stackify::LogGroup.encode(log_group)
        client = NetX::HTTPUnix.new('unix:///usr/local/stackify/stackify.sock')
        req = Net::HTTP::Post.new("/log")
        req.set_content_type('application/x-protobuf')
        req.body = message
        response = client.request(req)
        Stackify.internal_log :info, "[UnixSocketSender] Sending batch of msgs is successfully completed"
      rescue => exception
        Stackify.log_internal_error('[UnixSocketSender] send_logs() error: ', exception)
      end
    end
  end
end
