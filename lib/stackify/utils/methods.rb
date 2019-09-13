module Stackify::Utils

  def self.current_minute
    Time.now.utc.to_i/60
  end

  def self.rounded_current_time
    t = Time.now.utc
    t - t.sec
  end

  def self.is_mode_on? mode
    Stackify.configuration.mode = mode || Stackify::MODES[:both]
  end

  def self.do_only_if_authorized_and_mode_is_on mode, &block
    if Stackify.configuration.api_enabled
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

  def self.is_api_enabled
    exclude = %w/rake rspec irb/
    cmd = $PROGRAM_NAME.to_s.split('/').pop
    found = exclude.select{|e| e =~ /#{cmd}/i}
    Stackify.configuration.api_enabled = false if found.count > 0
  end
end