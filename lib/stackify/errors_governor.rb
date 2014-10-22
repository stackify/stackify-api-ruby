require 'digest'

module Stackify
  class ErrorsGovernor

    def initialize purge_period=5
      @history = {}
      @@history_lock = Mutex.new
      @purge_period = purge_period
      update_purge_times
    end

    def can_send? ex
      key = unique_key_of(ex)
      @@history_lock.synchronize do
        epoch_minute = current_minute
        init_history_key_if_not_exists key, epoch_minute
        history_entry = @history[key]
        if history_entry[:epoch_minute] == epoch_minute
          history_entry[:count] += 1
          answer = history_entry[:count] <= Stackify.configuration.flood_limit
        else
          @history[key]={
            epoch_minute: epoch_minute,
            count: 1
          }
          answer = true
        end
        clear_old_history_entries if time_for_purge_is_come?
        answer
      end
    end

    private

    def unique_key_of ex
      str = "#{ex.backtrace[0]['LineNum']}-#{ex.source_method}-#{ex.error_type}"
      Digest::MD5.hexdigest str
    end

    def init_history_key_if_not_exists key, minute
      @history[key] ||= {
        epoch_minute: minute,
        count: 0
      }
    end

    def clear_old_history_entries
      @history.keep_if{ |_key, entry| entry[:epoch_minute] == current_minute }
      update_purge_times
    end

    def update_purge_times
      @last_purge_minute = current_minute
      @next_purge_minute = @last_purge_minute + @purge_period
    end

    def current_minute
      Time.now.to_i/60
    end

    def time_for_purge_is_come?
      !(current_minute < @next_purge_minute)
    end
  end
end
