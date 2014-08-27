module Stackify

  class Configuration

    attr_accessor :api_key, :app_name, :app_location, :env, :log_level, :logger, :with_proxy,
                  :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :mode, :base_api_url

    attr_reader :errors, :send_interval, :flood_limit, :queue_max_size

    def initialize
      @base_api_url = 'https://api.stackify.com'
      @errors = []
      @api_key = ''
      @env = :production
      @flood_limit = 100
      @queue_max_size = 1000
      @send_interval = 60
      @with_proxy = false
      @log_level = :info
      @mode = MODES[:both]
      @logger = if defined? Rails
        Logger.new(File.join(Rails.root, 'log', 'stackify.log'))
      else
        Logger.new('stackify.log')
      end
    end

    def is_valid?
      @errors = []
      validate_mode if validate_config_types
      @errors.empty?
    end

    private

    def validate_config_types
      validate_api_key &&
      validate_log_level &&
      validate_mode_type
    end

    def validate_mode_type
      return true if @mode.is_a? Symbol
      @errors << 'Mode should be a Symbol'
    end

    def validate_api_key
      return true if  @api_key.is_a?(String) && !@api_key.empty?
      @errors << 'API_KEY should be a String and not empty'
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
