module Stackify::Metrics
  class GetMetricRequest
    attr_accessor :category, :metric_name, :device_id,
                  :device_app_id, :app_name_id, :metric_type_id

    def initialize aggr_metric
      @metric_name = aggr_metric.name
      @metric_type_id = aggr_metric.metric_type
      @category = aggr_metric.category
      @device_app_id = Stackify::EnvDetails.instance.auth_info['DeviceAppID']
      @device_id = Stackify::EnvDetails.instance.auth_info['DeviceID']
      @app_name_id = Stackify::EnvDetails.instance.auth_info['AppNameID']
    end

    def to_h
      {
        'DeviceAppID' => @device_app_id,
        'DeviceID' => @device_id,
        'AppNameID' => @app_name_id,
        'MetricName' => @metric_name,
        'MetricTypeID' => @metric_type_id,
        'Category' => @category
      }
    end
  end

  class GetMetricResponse
    attr_accessor :monitor_id
  end


end
