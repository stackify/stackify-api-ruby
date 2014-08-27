require 'uri'
require 'net/http'
require 'net/https'
module Stackify
  class HttpClient

    HEADERS = {
      'X-Stackify-PV' => 'V1',
      'X-Stackify-Key' => Stackify.configuration.api_key,
      'Content-Type' =>'application/json'
    }
    attr_reader :response, :errors

    private

    def send_request uri, body, headers = HEADERS
      @errors = []
      begin
        https = get_https uri
        req = Net::HTTP::Post.new uri.path, initheader = headers
        req.body = body
        Stackify.internal_log :debug, "============Request body=========================="
        Stackify.internal_log :debug, req.body
        Stackify.internal_log :debug, "=================================================="
        @response = https.request req
       rescue => ex
        @errors << ex
        Stackify.log_internal_error('HttpClient: ' + ex.message+ ' Backtrace: '+ Stackify::Backtrace.backtrace_in_line(ex.backtrace))
        false
      end
    end

    def get_https uri
      if Stackify.configuration.with_proxy
        https = Net::HTTP.new uri.host, uri.port,
                Stackify.configuration.proxy_host,
                Stackify.configuration.proxy_port,
                Stackify.configuration.proxy_user,
                Stackify.configuration.proxy_pass
      else
        https = Net::HTTP.new uri.host, uri.port
      end
      https.use_ssl = true
      https
    end
  end
end
