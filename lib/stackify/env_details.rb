require 'socket'
require 'singleton'
module Stackify

  class EnvDetails
    include Singleton
    attr_reader :request_details

    def initialize
      rails_info = defined?(Rails) ? Rails::Info.properties.to_h : nil
      @info =  rails_info || { 'Application root' => Dir.pwd, 'Environment' => 'development'}
      @request_details = {}
      @app_name = app_name
      app_location = Stackify.configuration.app_location || @info['Application root']
      @details = {
        'DeviceName' => Socket.gethostname,
        'AppLocation' => app_location,
        'AppName' => @app_name,
        'ConfiguredAppName' => @app_name,
        'ConfiguredEnvironmentName' =>@info['Environment']
      }
    end

    def auth_info
      with_synchronize{ @details }
    end

    def update_auth_info info
      with_synchronize{ @details.merge! info }
    end

    def request_details= env
      request = request_instance env
      @request_details = {
        'webrequest_details' => {
          'Headers' => headers(env),
          'Cookies' => cookies(env),
          'QueryString' => request.try(:GET),
          'PostData' => request.try(:POST),
          'PostDataRaw' => request.try(:raw_post),
          'SessionData' => request.try(:session),
          'UserIPAddress' => request.try(:remote_ip) || request.try(:ip),
          'HttpMethod' => request.try(:request_method),
          'ReferralUrl' => request.referer,
          'RequestUrl' => request.try(:fullpath),
          'RequestUrlRoot' => request.try(:base_url),
          'RequestProtocol' => request.try(:scheme)
        },
        'server_variables' => server_variables(env),
        'uuid' => request.uuid
      }
    rescue => e
      warning = 'failed to capture request parameters: %p: %s' % [ e.class, e.message ]
      Stackify.logger.warn warning
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end

    def with_synchronize
      mutex.synchronize{ yield }
    end

    def app_name
      Stackify.configuration.app_name || Rails.application.config.session_options[:key].sub(/^_/,'').sub(/_session/,'') || 'Unknown'
    end

    def app_location
      Stackify.configuration.app_location
    end

    def cookies env
      env['action_dispatch.cookies'].try(:to_h)
    end

    def headers env
      env.reject{ |k| !(k.start_with?'HTTP_') }
    end

    def server_variables env
      {
        'server' => server_name(env['SERVER_SOFTWARE']),
        'version' => server_version(env['SERVER_SOFTWARE'])
      }
    end

    def server_name str
      str[/(^\S*)\//, 1]
    end

    def server_version str
      str[/\/(\S*)\s/, 1]
    end

    def request_instance env
      if defined? ActionDispatch::Request
        ActionDispatch::Request.new env
      else
        Rack::Request.new env
      end
    end

  end

end
