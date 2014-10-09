require 'thread'
module Stackify

  class Scheduler

    attr_accessor :period
    attr_reader :iterations

    def initialize
      @should_run = true
      @next_invocation_time = Time.now
      @period = ScheduleDelay.new
      @iterations = 0
      @attempts = 3
    end

    def setup(period, task)
      @task = task
      @period = period if period
      @should_run = true
      @iterations = 0
      @attempts = @task.attempts if @task.attempts
      now = Time.now
      @next_invocation_time = (now + @period.to_sec)
    end

    def run(period=nil, task)
      setup(period, task)
      while keep_running? do
        sleep_time = schedule_next_invocation
        sleep(sleep_time) if sleep_time > 0 && @iterations != 0
        @task_result = run_task if keep_running?
        if @task.success? @task_result
          @iterations += 1
          @attempts = @task.attempts || @attempts
        else
          @period.update_by_exeption!(@task_result)
          @attempts -= 1
        end
      end
      @task.success? @task_result
    end

    def schedule_next_invocation
      now = Time.now
      while @next_invocation_time <= now && @period.to_sec > 0
        @next_invocation_time += @period.to_sec
      end
      @next_invocation_time - Time.now
    end

    def keep_running?
      @should_run && limit_is_not_reached? && attemps_are_not_over?
    end

    def attemps_are_not_over?
      @attempts.nil? || @attempts > 0
    end

    def limit_is_not_reached?
      @task.limit.nil? || @iterations < @task.limit
    end

    def stop
      @should_run = false
    end

    def task_result
      @task_result
    end

    def run_task
      begin
        @task.execute!
      rescue Exception => e
        ::Stackify.log_internal_error 'Scheduler: ' + e.message + '' + e.backtrace.to_s
      end
    end
  end
end
