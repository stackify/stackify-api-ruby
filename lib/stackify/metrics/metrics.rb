module Stackify
  module Metrics
    require_relative 'metrics_queue'
    require_relative 'metric'
    require_relative 'metric_aggregate'
    require_relative 'monitor'
    require_relative 'metrics_client'
    require_relative 'metrics_sender'

    METRIC_TYPES = {
      metric_last: 134,
      counter: 129,
      metric_average: 132,
      counter_time: 131
    }
    class << self
      def metrics_client
        @@metrics_client ||= Stackify::Metrics::MetricsClient.new
      end

      def average category, metric_name, value, advanced_settings = nil
        m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:metric_average]
        m.value = value
        m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric m
      end

      def count category, metric_name, increment_by= 1, advanced_settings = nil
        m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:counter]
        m.value = increment_by
        m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric m
      end

      def get_latest category, metric_name
        metrics_client.get_latest category, metric_name
      end

      def get_latest_all_metrics
        metrics_client.get_latest_all_metrics
      end

      def increment_gauge category, metric_name, increment_by = 1, advanced_settings = nil
        m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:metric_last]
        m.value = increment_by
        m.is_increment = true
        m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric m
      end

      def set_gauge category, metric_name, value, advanced_settings = nil
        m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:metric_last]
        m.value = value
        m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric m
      end

      def sum category, metric_name, value, advanced_settings = nil
        m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:counter]
        m.value = value
        m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric m
      end

      def time category, metric_name, start_time, advanced_settings = nil
        time_taken = Time.now.utc - start_time.utc
        avarage_time category, metric_name, time_taken, advanced_settings
      end

      def time_duration category, metric_name, duration_time, advanced_settings = nil
        avarage_time category, metric_name, duration_time, advanced_settings
      end

      def avarage_time category, metric_name, elapsed_time, advanced_settings = nil
        m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:counter_time]
        m.value = elapsed_time.round #seconds
        m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric m
      end

      def count_and_time category, metric_name, start_time, advanced_settings = nil
        counter_m = Metric.new category, metric_name, Stackify::Metrics::METRIC_TYPES[:counter]
        counter_m.value = 1
        counter_m.settings = advanced_settings
        time_m = Metric.new category, metric_name + ' Time', Stackify::Metrics::METRIC_TYPES[:counter_time]
        time_m.value = (Time.now.utc - start_time.utc).round
        time_m.settings = advanced_settings
        Stackify::Metrics.metrics_client.queue_metric counter_m
        Stackify::Metrics.metrics_client.queue_metric time_m
      end
    end
  end
end
