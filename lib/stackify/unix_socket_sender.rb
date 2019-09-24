require 'net_http_unix'

module Stackify
  class UnixSocketSender

    def send_logs msgs, attempts = 3
      begin
        details = Stackify::EnvDetails.instance.set_rails_info
        log_group = Stackify::LogGroup.new
        msgs.each do |msg|
          log_group.logs << msg
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
        puts "status: #{response.code}"
        Stackify.internal_log :info, "[UnixSocketSender] Sending batch of msgs is successfully completed"
      rescue => exception
        raise exception
      end
    end
  end
end
