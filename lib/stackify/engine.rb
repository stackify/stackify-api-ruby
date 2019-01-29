require 'stackify/rack/errors_catcher'
module Stackify
  class Engine < ::Rails::Engine

    if Rails.version > '3.1'

      initializer 'Stackify set up of logger', group: :all do
        ::Rails.logger = ::Stackify::LoggerProxy.new ::Rails.logger
        Stackify.run
      end

      initializer 'stackify.middleware', group: :all do |app|
        app.config.app_middleware.use Stackify::ErrorsCatcher do |env|
          Stackify::EnvDetails.instance.request_details = env
        end
      end

    end

  end
end
