module Stackify::Metrics
  class MetricAggregate

    attr_accessor :name, :category, :value, :count, :occurred_utc,
                  :monitor_id, :metric_type, :name_key

    def initialize metric
      @name = metric.name
      @category = metric.category
      @metric_type = metric.metric_type
      @value = 0
      @count = 0
      @occurred_utc = metric.get_rounded_time
      @name_key = metric.calc_name_key
    end

    def aggregate_key
      (@category || 'Missing Category').downcase + '-' + (@name || 'Missing Name').downcase +
      '-' + @metric_type.to_s + '-' + @occurred_utc.to_s
    end

  end

  class LatestAggregate
    attr_accessor :category, :name, :metric_id, :occurred_utc,
                  :value, :count, :metric_type

    def initialize aggr_metric
      @count = aggr_metric.count
      @metric_type = aggr_metric.metric_type
      @metric_id = aggr_metric.monitor_id
      @name = aggr_metric.name
      @occurred_utc = aggr_metric.occurred_utc
      @value = aggr_metric.value
      @count = aggr_metric.count
      @category = aggr_metric.category
    end

    def to_h
      {
        'Count' => @count,
        'MetricType' => @metric_type,
        'MetricID' => @metric_id,
        'Name' => @name,
        'OccurredUtc' => @occurred_utc,
        'Value' => @value,
        'Count' => @count,
        'Category' => @category
      }
    end
  end
end
