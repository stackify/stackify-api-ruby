module Stackify

  class Configuration

    attr_accessor :api_key, :app_name, :app_location, :env, :log_level, :logger,
                  :proxy, :mode, :base_api_url, :api_enabled, :transport, :errors

    attr_reader :send_interval, :flood_limit, :queue_max_size, :unix_socket_path, :unix_socket_url

    def initialize
      @base_api_url = 'https://api.stackify.com'
      @errors = []
      @app_name = ''
      @api_key = ''
      @transport = 'default'
      @env = :production
      @flood_limit = 100
      @queue_max_size = 10000
      @send_interval = 60
      @api_enabled = true
      @log_level = :info
      @mode = MODES[:both]
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::UNKNOWN
      @unix_socket_path = '/usr/local/stackify/stackify.sock'
      @unix_socket_url = '/log'
    end

    def is_valid?
      case Stackify.configuration.transport
      when Stackify::DEFAULT
        validate_default_transport
      when Stackify::UNIX_SOCKET
        validate_unix_domain_socket_transport
      end
      @errors.empty?
    end

    def validate_transport_type
      return true if ['agent_socket', 'default'].include? @transport
      @errors << 'Transport should be one of these values: [agent_socket, default]. Should be a String.'
    end

    private

    def validate_config_types
      validate_api_key &&
      validate_log_level &&
      validate_mode_type
    end

    # Perform validation if transport type is default
    # Required parameters are: env, app_name, api_key, log_level
    def validate_default_transport
      validate_app_name &&
      validate_transport_type &&
      validate_api_key &&
      validate_env &&
      validate_log_level &&
      validate_mode_type
    end

    # Perform validation if transport type is agent_socket
    # Required parameters are: env, app_name, log_level
    def validate_unix_domain_socket_transport
      validate_env &&
      validate_transport_type &&
      validate_app_name &&
      validate_log_level &&
      validate_mode_type
    end

    def validate_mode_type
      return true if @mode.is_a? Symbol
      @errors << 'Mode should be a Symbol'
    end

    def validate_api_key
      return true if  @api_key.is_a?(String) && !@api_key.empty?
      @errors << 'Api_key should be a String and not empty'
    end

    def validate_app_name
      return true if  @app_name.is_a?(String) && !@app_name.empty?
      @errors << 'App_name should be a String and not empty'
    end

    def validate_env
      return true if  @env.is_a?(Symbol) && !@env.empty?
      @errors << 'Env should be a Symbol and not empty'
    end

    def validate_log_level
      return true if  [:debug, :warn, :info, :error, :fatal].include? @log_level
      @errors << "Log's level should has one of these values: [:debug, :warn, :info, :error, :fatal]"
    end

    def validate_mode
      return true if MODES.has_value? @mode
      @errors << 'Mode should be one of these values: [:both, :logging, :metrics]'
    end
  end
end
