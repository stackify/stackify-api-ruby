module Stackify::Authorizable
  class AuthorizationClient < Stackify::HttpClient

    BASE_URI = URI("#{Stackify.configuration.base_api_url}/Metrics/IdentifyApp")

    def initialize
      super
      @worker = Stackify::AuthWorker.new
    end

    def auth attempts, delay_time= Stackify::ScheduleDelay.new
      task = auth_task attempts
      @worker.perform delay_time, task
    end

    def auth_task attempts
      begin
        properties = {
          limit: 1,
          attempts: attempts,
          success_condition: lambda do |result|
            result.try(:status) == 200
          end
        }
        Stackify::ScheduleTask.new properties do
          Stackify.internal_log :debug, '[AuthorizationClient] trying to authorize...'
          send_request BASE_URI, Stackify::EnvDetails.instance.auth_info.to_json
        end
      rescue => exception
        Stackify.log_internal_error "[AuthorizationClient]: An error occured in auth_task!"
      end
    end
  end
end
