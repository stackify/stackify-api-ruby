class DummyLogger
    attr_reader :logs
    attr_accessor :level

    def initialize
      @logs = []
    end
  
    def debug(message)
      log('debug', message)
    end
  
    def info(message)
      log('info', message)
    end
  
    def warn(message)
      log('warn', message)
    end
  
    def error(message)
      log('error', message)
    end
  
    def fatal(message)
      log('fatal', message)
    end
  
    def unknown(message)
      log('unknown', message)
    end

    def broadcast_to(arg1, arg2)
    end
  
    private
  
    def log(level, message)
      @logs << { level: level, message: message }
    end
end