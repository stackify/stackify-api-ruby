module Stackify::Metrics
  class MetricsSender < Stackify::HttpClient
    SUBMIT_METRIS_URI = URI("#{Stackify.configuration.base_api_url}/Metrics/SubmitMetricsByID")
    GET_METRIC_INFO_URI = URI("#{Stackify.configuration.base_api_url}/Metrics/GetMetricInfo")

    def monitor_info aggr_metric
      if Stackify.authorized?
        send_request GET_METRIC_INFO_URI, GetMetricRequest.new(aggr_metric).to_h.to_json
      else
        Stackify.log_internal_error "Getting of monitor_info is failed because of authorisation failure"
      end
    end

    def upload_metrics aggr_metrics
      return true if aggr_metrics.nil? || aggr_metrics.length == 0
      if Stackify.authorized?
        records = []
        aggr_metrics.each_pair do |_key, metric|
          records << Stackify::Metrics::MetricForSubmit.new(metric).to_h
          prms = [metric.category, metric.name, metric.count, metric.value, metric.monitor_id ]
          Stackify.internal_log :debug, 'Uploading metric: %s: %s count %s, value %s, ID %s' %  prms
        end
        send_request SUBMIT_METRIS_URI, records.to_json
      else
        Stackify.log_internal_error "Uploading of metrics is failed because of authorisation failure"
      end
    end
  end
end
