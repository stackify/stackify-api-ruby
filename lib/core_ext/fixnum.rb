class Fixnum
  SECONDS_IN_MINUTE = 60
  SECONDS_IN_HOUR =  60 * SECONDS_IN_MINUTE
  SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR

  def days
    begin
      super
    rescue
      self * SECONDS_IN_DAY
    end
  end

  def minutes
    begin
      super
    rescue
      self * SECONDS_IN_MINUTE
    end
  end

  def ago
    begin
      super
    rescue
      Time.now - self
    end
  end
end
