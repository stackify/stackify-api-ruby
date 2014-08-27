module Stackify::Authorizable
  class AuthorizationClient < Stackify::HttpClient

    BASE_URI = URI("#{Stackify.configuration.base_api_url}/Metrics/IdentifyApp")

    def initialize
      super
      @worker = Stackify::AuthWorker.new
    end

    def auth attempts, delay_time= 20
      task = auth_task attempts
      @worker.perform delay_time, task
    end

    def auth_task attempts
      properties = {
        limit: 1,
        attempts: attempts,
        success_condition: lambda do |result|
          result.try(:code) == '200'
        end
      }
      Stackify::ScheduleTask.new properties do
        Stackify.internal_log :debug, 'AthorizationClient: trying to athorize...'
        send_request BASE_URI, Stackify::EnvDetails.instance.auth_info.to_json
      end
    end
  end
end
