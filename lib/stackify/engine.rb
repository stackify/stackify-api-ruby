require 'stackify/rack/errors_catcher'
module Stackify
  class Engine < ::Rails::Engine

    if Rails.version > '3.1'
      initializer 'Stackify set up of logger', group: :all do
        if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('4.0')
          # check if the client app is using the ActiveSupport::Logger
          is_activesupport_logger = ::Rails.logger.is_a?(ActiveSupport::Logger)
        elsif Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('3.0')
          Stackify::Utils.check_buffered_logger
        end

        # Check if the log output is STDOUT
        Stackify::Utils.check_log_output

        # Proxy the client Rails logger and write logs to its default log_path.
        # At the same time, we send the log messages to the LoggerClient.
        ::Rails.logger = ::Stackify::LoggerProxy.new ::Rails.logger

        if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('6.0')
          set_console_logs ::Rails.logger
        elsif Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('4.0')
          if is_activesupport_logger && Stackify.configuration.stdout_output
            set_console_logs ::Rails.logger
          end
          # Another checking if the client app is using the default logger and not STDOUT
          if Stackify.configuration.stdout_output == false
            set_console_logs ::Rails.logger
          end
        end

        Stackify.run
      end

      initializer 'stackify.middleware', group: :all do |app|
        app.config.app_middleware.use Stackify::ErrorsCatcher do |env|
          Stackify::EnvDetails.instance.request_details = env
        end
      end

      def set_console_logs new_logger
        if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('6.0')
          ActiveSupport.on_load(:action_controller_base) do
            logger = new_logger
          end
          ActiveSupport.on_load(:action_view) do
            logger = new_logger
          end
          ActiveSupport.on_load(:active_record) do
            logger = new_logger
          end
        else
          # Handle the stdout logs from Action Controller
          ActionController::Base.logger = new_logger

          # Handle the stdout logs from Action View
          ActionView::Base.logger = new_logger

          # Handle the stdout logs from Active Record
          ActiveRecord::Base.logger = new_logger
        end
      end
    end

  end
end
