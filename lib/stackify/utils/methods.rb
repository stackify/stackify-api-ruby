module Stackify::Utils

  def self.current_minute
    Time.now.utc.to_i/60
  end

  def self.rounded_current_time
    t = Time.now.utc
    t - t.sec
  end

  def self.is_mode_on? mode
    Stackify.configuration.mode = mode || Stackify::MODES[:both]
  end

  def self.do_only_if_authorized_and_mode_is_on mode, &block
    begin
      if Stackify.configuration.api_enabled
        if Stackify.authorized?
          if is_mode_on? mode
            yield
          else
            Stackify.internal_log :warn, "[Stackify::Utils] - #{caller[0]}: Skipped because mode - #{mode.to_s} is disabled at configuration"
          end
        else
          Stackify.internal_log :warn, "[Stackify::Utils] - #{caller[0]}: Skipped due to authorization failure"
        end
      end
    rescue => ex
      Stackify.internal_log :warn, "[Stackify::Utils] do_only_if_authorized_and_mode_is_on ex: #{ex.inspect}"
    end
  end

  def self.is_api_enabled
    exclude = %w/rake rspec irb/
    cmd = $PROGRAM_NAME.to_s.split('/').pop
    found = exclude.select{|e| e =~ /#{cmd}/i}
    Stackify.configuration.api_enabled = false if found.count > 0
  end

  def self.get_app_settings
    @env = {
      'env' => Stackify.configuration.env,
      'app_name' => Stackify.configuration.app_name,
      'server_name' => Socket.gethostname,
      'app_location' => Stackify.configuration.app_location || Dir.pwd
    }
  end

  # Check if the app is running on rails and the logger output is using STDOUT
  def self.check_log_output
    if defined? Rails
      if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('5.0')
        Stackify.configuration.stdout_output = ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDOUT)
      else
        Stackify.configuration.stdout_output = self.logger_stdout
      end
    end
  end

  def self.logger_stdout
    logdev = ::Rails.logger.instance_variable_get(:@logdev)
    logger_source = logdev.dev if logdev.respond_to?(:dev)
    sources = [$stdout]
    found = sources.any? { |source| source == logger_source }
  end

  # Check if the rails version 3 and it's using the buffered logger
  def self.check_buffered_logger
    is_buffered_logger = false
    is_buffered_logger = true if ::Rails.logger.is_a?(ActiveSupport::BufferedLogger)
    Stackify.configuration.buffered_logger = is_buffered_logger
  end
end
