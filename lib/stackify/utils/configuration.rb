module Stackify

  class Configuration

    attr_accessor :api_key, :app_name, :app_location, :env, :log_level, :flood_limit,
                  :queue_max_size, :logger, :send_interval, :with_proxy,
                  :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :mode

    attr_reader :errors

    def initialize
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
      validate_send_interval && validate_mode if validate_config_types
      @errors.empty?
    end

    private
    def validate_send_interval
      return true if 60 <= @send_interval && @send_interval <= 60000
      @errors << 'Send interval is not correct!'
    end

    def validate_config_types
      validate_api_key &&
      validate_flood_limit_queue_max_size_and_send_interval &&
      validate_log_level &&
      validate_mode_type
    end

    def validate_mode_type
      return true if @mode.is_a? Symbol
      @errors << 'Mode should be a Symbol'
    end

    def validate_api_key
      return true if  @api_key.is_a? String
      @errors << 'API_KEY should be a String'
    end

    def validate_flood_limit_queue_max_size_and_send_interval
      answer = true
      { 'Flood limit' => @flood_limit, "Queue's max size" => @queue_max_size, 'Send interval' => @send_interval }.each_pair do |k, v|
        unless v.is_a? Integer
          answer = false
          @errors << "#{k} should be an Integer"
        end
      end
      answer
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
