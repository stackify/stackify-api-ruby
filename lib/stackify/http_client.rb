require 'uri'
require 'faraday'

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
        conn = Faraday.new(proxy: Stackify.configuration.proxy)
        Stackify.internal_log :debug, "============Request body=========================="
        Stackify.internal_log :debug, body
        Stackify.internal_log :debug, "=================================================="
        @response = conn.post do |req|
                      req.url URI(uri)
                      req.headers = headers
                      req.body = body
                    end
      rescue => ex
        @errors << ex
        Stackify.log_internal_error('HttpClient: ' + ex.message+ ' Backtrace: '+ Stackify::Backtrace.backtrace_in_line(ex.backtrace))
        false
      end
    end

  end
end
