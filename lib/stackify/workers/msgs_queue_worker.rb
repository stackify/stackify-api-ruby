module Stackify
  class MsgsQueueWorker < Worker

    def initialize name = 'MsgsQueue worker'
      super
      @type = :send_msgs
      Stackify.internal_log :info, "#{@name}: started sending logs"
    end

    def after_perform result
    end
  end
end
