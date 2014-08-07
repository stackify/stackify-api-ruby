module Stackify::Utils

  def self.current_minute
    Time.now.utc.to_i/60
  end

  def self.rounded_current_time
    t = Time.now.utc
    t - t.sec
  end

  def self.is_mode_on? mode
    Stackify.configuration.mode == Stackify::MODES[:both] || Stackify.configuration.mode == mode
  end

  def self.do_only_if_authorized_and_mode_is_on mode, &block
    if Stackify.authorized?
      if is_mode_on? mode
        yield
      else
        Stackify.internal_log :warn, "#{caller[0]}: Skipped because mode - #{mode.to_s} is disabled at configuration"
      end
    else
      Stackify.internal_log :warn, "#{caller[0]}: Skipped due to authorization failure"
    end
  end
end
