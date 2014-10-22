class Fixnum
  SECONDS_IN_MINUTE = 60
  SECONDS_IN_HOUR =  60 * SECONDS_IN_MINUTE
  SECONDS_IN_DAY = 24 * SECONDS_IN_HOUR

  def days
    self * SECONDS_IN_DAY
  end

  def minutes
    self * SECONDS_IN_MINUTE
  end

  def ago
    Time.now - self
  end
end
