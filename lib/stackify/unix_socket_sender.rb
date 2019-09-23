
require 'net/http'
require 'net_http_unix'

module Stackify
  class UnixSocketSender

    def send_logs msgs, attempts = 3
      begin
        puts 'UnixSocketSender.send_logs()'
        date_millis = '1417535434194'
        log = Stackify::LogGroup::Log.new
        log.message = 'some logs'
        log.thread_name = 'Main'
        log.date_millis = date_millis.to_i
        log.level = 'DEBUG'
        log.source_method = 'some_method'
        log.source_line = 13
        log.id = date_millis

        log_group = Stackify::LogGroup.new
        log_group.environment = 'Test'
        log_group.server_name = 'Ruby Test'
        log_group.application_name = 'Ruby Test Script'
        log_group.application_location = 'some/location/app'
        log_group.logger = 'Logger'
        log_group.platform = 'ruby'
        log_group.logs << log
        message = Stackify::LogGroup.encode(log_group)

        client = NetX::HTTPUnix.new('unix:///usr/local/stackify/stackify.sock')
        req = Net::HTTP::Post.new("/log")
        req.set_content_type('application/x-protobuf')
        req.body= message
        response = client.request(req)
        puts 'status:'
        puts response.code
      rescue => exception
        puts exception
        File.open("./MYLOG.txt", 'a') { |file|
          file.puts 'exception: '
          file.puts exception
        }
      end
    end
  end
end
