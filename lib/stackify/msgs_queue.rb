module Stackify
  class MsgsQueue < SizedQueue
    include MonitorMixin

    CHUNK_MIN_WEIGHT = 50
    ERROR_SIZE = 10
    LOG_SIZE = 1
    DELAY_WAITING = 1

    def initialize
      super(Stackify.configuration.queue_max_size)
      if Stackify::Utils.is_mode_on? Stackify::MODES[:logging]
        @send_interval = ScheduleDelay.new
        worker = MsgsQueueWorker.new
        task = update_send_interval_task
        worker.async_perform @send_interval, task
      else
        Stackify.internal_log :warn, '[MsgsQueue]: Logging is disabled at configuration!'
      end
    end

    alias :old_push :push

    def push_remained_msgs
      wait_until_all_workers_will_add_msgs
      self.synchronize do
        Stackify.internal_log :info, 'All remained logs are going to be sent'
        Stackify.shutdown_all
        if self.length > 0
          Stackify.logs_sender.send_logs(pop_all)
          Stackify.status = Stackify::STATUSES[:terminated]
        end
      end
    end

    def add_msg msg
      self.synchronize do
        Stackify::Utils.do_only_if_authorized_and_mode_is_on Stackify::MODES[:logging] do
          old_push(msg)
        end
      end
    end

    alias :<< :add_msg
    alias :push :add_msg

    private

    def pop_all
      self.synchronize do
        msgs = []
        until self.empty? do
          msgs << self.pop
        end
        msgs
      end
    end

    def wait_until_all_workers_will_add_msgs
      @send_interval = 120
      while Stackify.alive_adding_msg_workers.size > 0
        @send_interval += DELAY_WAITING
        sleep DELAY_WAITING
      end
    end

    def update_send_interval_task
    properties = {
        success_condition: lambda do |result|
          true
        end
      }
      Stackify::ScheduleTask.new properties do
        processed_count = calculate_processed_msgs_count
        i = @send_interval.update_by_sent_num! processed_count
        Stackify.internal_log :debug, "MsgsQueue: send_interval is updated to #{i}"
        i
      end
    end

    def calculate_processed_msgs_count
      processed_count = 0
      keep_going = true
      begin
        count = push_one_chunk
        keep_going = count >= 50
        processed_count += count
      end while keep_going
      processed_count
    end

    def push_one_chunk
      chunk_weight = 0
      chunk = []
      started_at = Time.now.to_f * 1000
      self.synchronize do
        while(true)
          if length > 0
            msg = pop
            chunk << msg
            chunk_weight += (msg['Ex'].nil? ? LOG_SIZE : ERROR_SIZE)
            break if msg['EpochMs'] > started_at || CHUNK_MIN_WEIGHT > 50
          else
            break
          end
        end

        Stackify.logs_sender.send_logs(chunk) if chunk.length > 0
        chunk_weight
      end
    end
  end
end
