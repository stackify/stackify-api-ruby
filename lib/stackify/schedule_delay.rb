module Stackify
  class ScheduleDelay

    ONE_SECOND = 1.0
    ONE_MINUTE = 60.0
    FIVE_SECONDS = 5.0
    FIVE_MINUTES = 300.0

    def initialize (delay = ONE_SECOND)
      @delay = delay
      @last_http_error_occured_time = 0
    end

    def update_by_sent_num! num_sent
      @last_http_error_occured_time = 0
      if num_sent >= 100
        @delay = [(@delay/ 2.0).round(2), ONE_SECOND].max
      elsif num_sent < 10
        @delay = [(@delay * 1.25).round(2), FIVE_SECONDS].min
      end
    end

    def update_by_exeption! e
      if is_authorized_exeption?(e)
        @last_http_error_occured_time = Time.now if @last_http_error_occured_time == 0
        since_first_error = (Time.now - @last_http_error_occured_time).round(2)
        @delay = [[since_first_error, ONE_SECOND].max, ONE_MINUTE].min
      else
        @last_http_error_occured_time = Time.now
        @delay = FIVE_MINUTES
      end
    end

    def to_sec
      @delay
    end

    private

    def is_authorized_exeption? ex
      ex.try(:status) == 401
    end
  end

end
