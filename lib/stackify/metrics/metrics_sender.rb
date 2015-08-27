module Stackify::Metrics
  class MetricsSender < Stackify::HttpClient
    SUBMIT_METRIS_URI = URI("#{Stackify.configuration.base_api_url}/Metrics/SubmitMetricsByID")
    GET_METRIC_INFO_URI = URI("#{Stackify.configuration.base_api_url}/Metrics/GetMetricInfo")

    def monitor_info aggr_metric
      if Stackify.authorized?
        send_request GET_METRIC_INFO_URI, GetMetricRequest.new(aggr_metric).to_h.to_json
      else
        Stackify.log_internal_error "Getting of monitor_info is failed because of authorization failure"
      end
    end

    def upload_metrics aggr_metrics
      return true if aggr_metrics.nil? || aggr_metrics.length == 0
      current_time = Stackify::Utils.rounded_current_time
      device_id = Stackify::EnvDetails.instance.auth_info['DeviceID']
      if Stackify.authorized?
        records = []
        aggr_metrics.each_pair do |_key, metric|
          next if metric.sent || metric.occurred_utc.to_i >= current_time.to_i
          record = Stackify::Metrics::MetricForSubmit.new(metric).to_h
          record['ClientDeviceID'] = device_id if !device_id.nil?
          records << record
          metric.sent = true
        end
        if records.any?
          Stackify.internal_log :debug, "Uploading Aggregate Metrics at #{ Time.now }: \n" + JSON.pretty_generate(records)
          response = send_request SUBMIT_METRIS_URI, records.to_json
          Stackify.internal_log :info, 'Metrics are uploaded successfully' if response.try(:status) == 200
        end
      else
        Stackify.log_internal_error "Uploading of metrics is failed because of authorization failure"
      end
    end
  end
end
