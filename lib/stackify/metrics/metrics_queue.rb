module Stackify::Metrics
  class MetricsQueue < SizedQueue
    include MonitorMixin

    def initialize
      super(Stackify.configuration.queue_max_size)
    end

    alias :old_push :push

    def add_metric metric
      self.synchronize do 
        self.old_push metric
      end
    end

    alias :old_size :size 

    def size 
      self.synchronize do 
        self.old_size
      end
    end
    
  end
end