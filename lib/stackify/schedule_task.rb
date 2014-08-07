module Stackify
  class ScheduleTask

    attr_reader :limit, :attempts, :action

    def initialize properties={}, &action
      @limit = properties[:limit] || nil
      @attempts = properties[:attempts] || 3
      @success_condition = properties[:success_condition] || lambda{ |_result| true }
      @action = action
    end

    def execute!
      @action.call
    end

    def success? result_of_task_execution
      @success_condition.call result_of_task_execution
    end

  end

end
