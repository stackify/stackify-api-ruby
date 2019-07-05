require 'thread'

module Stackify

  class Worker
    attr_reader :name, :type

    def initialize name = nil
      @type = :common
      @name = name ? name : generate_name
      @name += " ##{self.id}"
      @scheduler = Stackify::Scheduler.new
      Stackify.internal_log :info, "[Worker] Created worker: #{@name}"
      Stackify.add_dependant_worker self
    end

    def async_perform period=ScheduleDelay.new, task
      run_scheduler task, period
    end

    def perform period=ScheduleDelay.new, task
      run_scheduler task, period, true
    end

    def shutdown!
      Stackify.delete_worker self
      if @worker_thread
        Stackify.internal_log :debug, "Thread with name \"#{@name}\" is terminated!"
        Thread.kill @worker_thread
      else
        Stackify.internal_log :warn, "Thread with name \"#{@name}\" is terminated with exception!"
      end
    end

    def status
      @worker_thread.try(:status)
    end

    def backtrace
      @worker_thread.try(:backtrace)
    end

    def alive?
      @worker_thread.try(:alive?)
    end

    def id
      object_id
    end

    private
    def generate_name
      'Untitled worker'
    end

    def run_scheduler task, delay, sync = false
      @worker_thread = Thread.new do
        @scheduler.run delay, task
        after_perform @scheduler.task_result if respond_to? :after_perform
        shutdown!
      end
      @worker_thread.join if sync && @worker_thread.alive?
    end
  end

end
