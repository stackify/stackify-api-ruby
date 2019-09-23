
# require 'net/http'
require 'net_http_unix'

module Stackify
  class UnixSocketSender

    def send_logs msgs, attempts = 3
      begin
        details = Stackify::EnvDetails.instance.set_rails_info
        puts 'UnixSocketSender.send_logs()...'
        puts msgs
        log_group = Stackify::LogGroup.new
        msgs.each do |m|
          date_millis = m['EpochMs'].to_s
          log = Stackify::LogGroup::Log.new
          log.message = m['Msg'].to_s
          log.thread_name = m['Th'].to_s
          log.date_millis = date_millis.to_i
          log.level = m['Level'].to_s
          log.source_method = m['SrcMethod'].to_s
          log.source_line = m['SrcLine'].to_i
          log.id = date_millis.to_s
          log_group.logs << log
        end
        log_group.environment = details['ConfiguredEnvironmentName']
        log_group.server_name = details['DeviceName']
        log_group.application_name = details['AppName']
        log_group.application_location = details['AppLocation']
        log_group.logger = 'Logger'
        log_group.platform = 'ruby'
        message = Stackify::LogGroup.encode(log_group)

        client = NetX::HTTPUnix.new('unix:///usr/local/stackify/stackify.sock')
        req = Net::HTTP::Post.new("/log")
        req.set_content_type('application/x-protobuf')
        req.body = message
        response = client.request(req)
        puts 'status:'
        puts response.code
        Stackify.internal_log :info, "Sending batch of msgs is successfully completed"
      rescue => exception
        raise exception
      end
    end
  end
end
