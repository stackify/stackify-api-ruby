module Stackify::Metrics
  class MetricsClient

    attr_reader :metrics_queue

    def initialize
      @metrics_queue = MetricsQueue.new
      @last_aggregates = {}
      @metric_settings = {}
      @aggregate_metrics = {}
      @monitor_ids = {}
      @metrics_sender = MetricsSender.new
    end

    def start
      if Stackify::Utils.is_mode_on? Stackify::MODES[:metrics]
        worker = Stackify::Worker.new 'Metrics client - processing of metrics'
        Stackify.internal_log :debug, 'Metrics client: processing of metrics is started'
        task = submit_metrics_task
        worker.async_perform 5, task
      else
        Stackify.internal_log :warn, '[MetricClient]: Processing of metrics is disabled at configuration!'
      end
    end

    def get_latest category, metric_name
      Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:metrics] do
        l = @last_aggregates.select { |_key, aggr| aggr.category.eql?(category) && aggr.name.eql?(metric_name) }
        LatestAggregate.new l.values.first
      end
    end

    def get_latest_all_metrics
      Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:metrics] do
        all_latest = []
        @last_aggregates.each_pair do |_key, aggr|
          all_latest << Stackify::Metrics::LatestAggregate.new(aggr)
        end
        all_latest
      end
    end

    def queue_metric metric
      if Stackify.working?
        if Stackify::Utils.is_mode_on? Stackify::MODES[:metrics]
          @metrics_queue.add_metric metric
        else
          Stackify.internal_log :warn, '[MetricClient]: Adding of metrics is impossible because they are disabled by configuration'
        end
      else
        Stackify.internal_log :warn, '[MetricClient]: Adding of metrics is impossible - Stackify is terminating or terminated work.'
      end
    end
    
    private
    
    def start_upload_metrics
      all_is_ok = false
      current_time = Stackify::Utils.rounded_current_time
      purge_older_than = current_time - 10.minutes
      #read everything up to the start of the current minute
      read_queued_metrics_batch current_time
      handle_zero_reports current_time
      get_for_recent = @aggregate_metrics.select do |_k, v|
        v.occurred_utc < current_time && v.occurred_utc > current_time - 5.minutes
      end
      set_latest_aggregates get_for_recent
      selected_aggr_metrics = @aggregate_metrics.select { |_key, aggr| aggr.occurred_utc < current_time }
      first_50_metrics = Hash[selected_aggr_metrics.to_a.take 50]
      if first_50_metrics.length > 0
        #only getting metrics less than 10 minutes old to drop old data in case we get backed up
        #they are removed from the @aggregated_metrics in the upload function upon success
        all_success = upload_aggregates(first_50_metrics.select { |_key, aggr| aggr.occurred_utc > current_time - 10.minutes })
      end
      @aggregate_metrics.delete_if { |_key, aggr| aggr.occurred_utc < purge_older_than }
    end

    def read_queued_metrics_batch chosen_time
      batches = {}

      while  @metrics_queue.size > 0 do
        metric = @metrics_queue.pop
        metric.calc_and_set_aggregate_key
        unless batches.has_key? metric.aggregate_key
          name_key = metric.calc_name_key
          if metric.is_increment && @last_aggregates.has_key?(name_key)
            #if wanting to do increments we need to grab the last value so we know what to increment
            metric.value = @last_aggregates[name_key].value
          end
          batches[metric.aggregate_key] = MetricAggregate.new metric
          #if it is nil don't do anything
          #we are doing it where the aggregates are created so we don't do it one very single metric,
          #just once per batch to optimize performance

          @metric_settings[name_key] = metric.settings if metric.settings != nil
        end
        batches[metric.aggregate_key].count += 1
        if metric.is_increment
          #add or subtract
          batches[metric.aggregate_key].value += metric.value
        elsif metric.metric_type == Stackify::Metrics::METRIC_TYPES[:metric_last]
          #should end up the last value
          batches[metric.aggregate_key].value = metric.value
        else
          batches[metric.aggregate_key].value += metric.value
        end
        #we don't need anything more this recent so bail
        break if metric.occurred > chosen_time
      end
      batches.each_pair do |_key, aggregated_metric|
        aggregate aggregated_metric
      end
    end

    def aggregate am
      agg_key = am.aggregate_key
      if @aggregate_metrics.has_key? agg_key
        agg = @aggregate_metrics[agg_key]
      else
        if @aggregate_metrics.length > 1000
          str = 'No longer aggregating new metrics because more than 1000 are queued'
          Stackify.internal_log :warn, str
          return
        end
        Stackify.internal_log :debug, 'Creating aggregate for ' + agg_key
        @aggregate_metrics[agg_key] = am
        agg = Stackify::Metrics::Metric.new am.category, am.name, am.metric_type
        agg = MetricAggregate.new agg
        agg.occurred_utc = am.occurred_utc
      end

      if am.metric_type == Stackify::Metrics::METRIC_TYPES[:metric_last]
        agg.count = 1
        agg.value = am.value
      else
        agg.count += am.count
        agg.value += am.value
      end
      @aggregate_metrics[agg_key]= agg
    end

    def submit_metrics_task
      Stackify::ScheduleTask.new do 
        start_upload_metrics
      end
    end

    def handle_zero_reports current_time
      @last_aggregates.each_pair do |_key, aggregate|
        if @metric_settings.has_key? aggregate.name_key
          settings = @metric_settings[aggregate.name_key]
          if settings.nil?
            @metric_settings.delete[aggregate.name_key]
            next
          end
          #agg = MetricAggregate.new aggregate.category, aggregate.name, aggregate.metric_type
          agg = aggregate
          agg.occurred_utc = current_time
          case aggregate.metric_type
          when Stackify::Metrics::METRIC_TYPES[:metric_last]
            setting.autoreport_last_value_if_nothing_reported = false #do not allow this
          when Stackify::Metrics::METRIC_TYPES[:counter]
            setting.autoreport_last_value_if_nothing_reported = false #do not allow this
          end
          if settings.autoreport_zero_if_nothing_reported
            agg.count = 1
            agg.value = 0
          elsif settings.autoreport_last_value_if_nothing_reported
            agg.count = aggregate.value.to_i
            agg.value = aggregate.value
          else
            next
          end
          agg_key = agg.aggregate_key
          unless @aggregate_metrics.has_key? agg_key
            agg.name_key = aggregate.name_key
            Stackify.internal_log :debug, 'Creating 0 default value for ' + agg_key
            @aggregate_metrics[agg_key] = agg
          end
        end
      end
    end

    def set_latest_aggregates aggregates
      aggregates.each_pair do |_key, aggr|
        if @last_aggregates.has_key? aggr.name_key
          curr_aggr = @last_aggregates[aggr.name_key]
          @last_aggregates[aggr.name_key] = aggr if aggr.occurred_utc > curr_aggr.occurred_utc
        else
          @last_aggregates[aggr.name_key] = aggr
        end
      end
    end

    def upload_aggregates aggr_metrics
      s = ''
      aggr_metrics.each_pair do |_k, m|
        s = s + m.inspect.to_s + "\n --------------------------- \n"
      end
      Stackify.internal_log :debug, "Uploading Aggregate Metrics at #{ Time.now }: \n" + s
      all_success = true
      aggr_metrics.each_pair do |_key, metric|
        if @monitor_ids.has_key? metric.name_key
          mon_info = @monitor_ids[metric.name_key]
        else
          req = @metrics_sender.monitor_info metric
          if req.try(:code) == '200'
            mon_info = JSON.parse req.body
            if !mon_info.nil? && !mon_info['MonitorID'].nil? && mon_info['MonitorID'] > 0
              @monitor_ids[metric.name_key] = mon_info
            elsif !mon_info.nil? && mon_info['MonitorID'].nil?
              Stackify.internal_log :warn, 'Unable to get metric info for ' + metric.name_key + ' MonitorID is nil'
              @monitor_ids[metric.name_key] = mon_info
            end
          else
            Stackify.internal_log :error, 'Unable to get metric info for ' + metric.name_key
            mon_info = nil
            all_success = false
          end
        end

        if mon_info.nil? || mon_info['MonitorID'].nil?
          Stackify.internal_log :warn, 'Metric info missing for ' + metric.name_key
          metric.monitor_id = nil
          all_success = false
        else
          metric.monitor_id = mon_info['MonitorID']
        end

        #get identified once
        aggr_metrics_for_upload = aggr_metrics.select { |_key, aggr_metric| !aggr_metric.monitor_id.nil? }
        response = @metrics_sender.upload_metrics aggr_metrics_for_upload
        Stackify.internal_log :info, 'Metrics are uploaded successfully' if response.try(:code) == '200'
        all_success
      end
    end
  end
end
