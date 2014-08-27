module Stackify
  class MsgsQueue < SizedQueue
    include MonitorMixin
    #TODO: restrict possibility to work with class if app is off
    CHUNK_MIN_WEIGHT = 50
    ERROR_SIZE = 10
    LOG_SIZE = 1
    DELAY_WAITING = 2

    def initialize
      super(Stackify.configuration.queue_max_size)
      reset_current_chunk
    end

    alias :old_push :push

    def push_remained_msgs
      wait_until_all_workers_will_add_msgs
      self.synchronize do
        push_current_chunk
        Stackify.shutdown_all
        if self.length > 0
          Stackify.logs_sender.send_remained_msgs
          Stackify.internal_log :info, 'All remained logs are sent'
          Stackify.status = Stackify::STATUSES[:terminated]
        end
      end
    end

    def add_msg msg
      self.synchronize do
        if msg.is_a?(Hash)
          @current_chunk_weight += msg['Ex'].nil? ? LOG_SIZE : ERROR_SIZE
          @current_chunk << msg
          if @current_chunk_weight >= CHUNK_MIN_WEIGHT
            push_current_chunk
          end
        else
          Stackify.log_internal_error "MsgsQueue: add_msg should get hash, but not a #{msg.class}"
        end
      end
    end

    alias :<< :add_msg
    alias :push :add_msg

    def pop_all
      self.synchronize do
        msgs = []
        until self.empty? do
          msgs << self.pop
        end
        msgs
      end
    end

    private

    def reset_current_chunk
      @current_chunk = []
      @current_chunk_weight = 0
    end

    def wait_until_all_workers_will_add_msgs
      while Stackify.alive_adding_msg_workers.size > 0
        sleep DELAY_WAITING
      end
    end

    def push_current_chunk
      unless @current_chunk.empty?
        self.old_push(@current_chunk)
        reset_current_chunk
      end
    end
  end
end
