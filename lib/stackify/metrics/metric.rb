require 'date'
module Stackify::Metrics
  class Metric
    attr_accessor :category, :name, :metric_type, :is_increment,
                  :settings, :value, :aggregate_key, :occurred

    def initialize category, name, metric_type, metric_settings = nil
      @category = category
      @name = name
      @metric_type = metric_type
      @occurred = Time.now.utc
      @occurred = get_rounded_time
      @is_increment = false
      @settings = metric_settings || MetricSettings.new
    end

    def calc_and_set_aggregate_key
      @aggregate_key = @category.downcase + '-' + (@name || 'Missing Name').downcase +
                       '-' + @metric_type.to_s + '-' + get_rounded_time.to_s
    end

    def calc_name_key
      @category.downcase + '-' + (@name || 'Missing Name').downcase + '-' + @metric_type.to_s
    end

    def get_rounded_time
      @occurred - @occurred.sec
    end
  end

  class MetricSettings
    attr_reader :autoreport_zero_if_nothing_reported,
                :autoreport_last_value_if_nothing_reported

    def autoreport_last_value_if_nothing_reported= value
      @autoreport_last_value_if_nothing_reported = value
      @autoreport_zero_if_nothing_reported = false if value
    end

    def autoreport_zero_if_nothing_reported= value
      @autoreport_zero_if_nothing_reported = value
      @autoreport_last_value_if_nothing_reported = false if value
    end
  end

  class MetricForSubmit
    attr_accessor :monitor_id, :value, :count, :occurred_utc, :monitor_type_id

    def initialize metric
      @value = metric.value.round 2
      @monitor_id = metric.monitor_id || 0
      @occurred_utc = metric.occurred_utc
      @count = metric.count
      @monitor_type_id = metric.metric_type
    end

    def to_h
      {
        'Value' => @value,
        'MonitorID' => @monitor_id,
        'OccurredUtc' => DateTime.parse(@occurred_utc.to_s).iso8601,
        'Count' => @count,
        'MonitorTypeID' => @monitor_type_id
      }
    end
  end

end
