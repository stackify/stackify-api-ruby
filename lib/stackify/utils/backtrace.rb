module Stackify::Backtrace

  ALL_TEXT_FROM_START_TO_FIRST_COLON_REGEXP = /\A([^:]+)/
  NUMBER_BETWEEN_TWO_COLONS_REGEXP = /:(\d+):/
  TEXT_AFTER_IN_BEFORE_END_REGEXP = /in\s`(\S+)'\z/
  TEXT_AFTER_IN_BEFORE_END_REGEXP_ = /in\s(\S+)'\z/

  def self.line_number backtrace_str
    backtrace_str[NUMBER_BETWEEN_TWO_COLONS_REGEXP, 1]
  end

  def self.method_name backtrace_str
    return nil unless backtrace_str
    backtrace_str[TEXT_AFTER_IN_BEFORE_END_REGEXP, 1] || backtrace_str[TEXT_AFTER_IN_BEFORE_END_REGEXP_, 1]
  end

  def self.file_name backtrace_str
    backtrace_str[ALL_TEXT_FROM_START_TO_FIRST_COLON_REGEXP, 1]
  end

  def self.stacktrace depth=5, backtrace
    return nil unless backtrace
    new_backtrace = []
    backtrace.take(depth).each do |line|
      new_backtrace << {
        'LineNum' => line_number(line),
        'Method' => method_name(line),
        'CodeFileName' => file_name(line)
      }
    end
    new_backtrace
  end

  def self.backtrace_in_line backtrace
    backtrace.join("\n")
  end
end
