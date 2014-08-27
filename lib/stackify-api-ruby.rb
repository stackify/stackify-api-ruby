require 'stackify/version'
require 'stackify/utils/methods'
require 'core_ext/core_ext' unless defined? Rails

module Stackify

  INTERNAL_LOG_PREFIX = '[Stackify]'.freeze
  STATUSES = { working: 'working', terminating: 'terminating', terminated: 'terminated'}
  MODES = { logging: :logging, metrics: :metrics, both: :both }

  autoload :Backtrace,            'stackify/utils/backtrace'
  autoload :MsgObject,            'stackify/utils/msg_object'
  autoload :Configuration,        'stackify/utils/configuration'
  autoload :HttpClient,           'stackify/http_client'
  autoload :Authorizable,         'stackify/authorization/authorizable'
  autoload :EnvDetails,           'stackify/env_details'
  autoload :Scheduler,            'stackify/scheduler'
  autoload :ScheduleTask,         'stackify/schedule_task'
  autoload :Worker,               'stackify/workers/worker'
  autoload :AuthWorker,           'stackify/workers/auth_worker'
  autoload :LogsSenderWorker,     'stackify/workers/logs_sender_worker'
  autoload :AddMsgWorker,         'stackify/workers/add_msg_worker'
  autoload :MsgsQueue,            'stackify/msgs_queue'
  autoload :LoggerClient,         'stackify/logger_client'
  autoload :LogsSender,           'stackify/logs_sender'
  autoload :LoggerProxy,          'stackify/logger_proxy'
  autoload :StackifiedError,      'stackify/error'
  autoload :ErrorsGovernor,       'stackify/errors_governor'
  autoload :Metrics,              'stackify/metrics/metrics'

  include Authorizable

  class << self

    attr_writer :config

    def configuration
      @config ||= Stackify::Configuration.new
    end

    def setup
      @workers = []
      yield(configuration) if block_given?
      if configuration.is_valid?
        @status = STATUSES[:working]
      else
        msg = "Stackify's configuration is not valid!"
        configuration.errors.each do |error_msg|
          msg += "\n" + error_msg
        end
        raise msg
      end

    end

    def msgs_queue
      @msgs_queue ||= Stackify::MsgsQueue.new
    end

    def logger_client
      @logger_client ||= Stackify::LoggerClient.new
    end

    def logs_sender
      @logs_sender ||= Stackify::LogsSender.new
    end

    def logger
      self.configuration.logger
    end

    def shutdown_all caller_obj=nil
      Stackify.status = Stackify::STATUSES[:terminating]
      @workers.each do |worker|
        worker.shutdown! unless worker.equal? caller_obj
      end
    end

    def alive_adding_msg_workers
      @workers.select{ |w| w.alive? && w.type == :add_msg }
    end

    def delete_worker worker
      @workers.delete worker
    end

    def add_dependant_worker worker
      @workers << worker
    end

    def status
      @status
    end

    def log_internal_error msg
      Stackify.logger.error (::Stackify::INTERNAL_LOG_PREFIX){ msg }
    end

    def internal_log level, msg
      Stackify.logger.send(level.downcase.to_sym, Stackify::INTERNAL_LOG_PREFIX){ msg }
    end

    def run async = true
      if Stackify.is_valid?
        at_exit { make_remained_job }
        t1 = Thread.new { Stackify.authorize }
        case Stackify.configuration.mode
        when MODES[:both]
          t2 = start_logging
          t3 = start_metrics
        when MODES[:logging]
          t2 = start_logging
        when MODES[:metrics]
          t3 = start_metrics
        end
        unless async
          t1.join
          t2.join if t2
        end
      else
        Stackify.log_internal_error "Stackify is not properly configured! Errors: #{Stackify.configuration.errors}"
      end
    end

    def start_logging
      Thread.new { Stackify.logs_sender.start}
    end

    def start_metrics
      Thread.new { Stackify::Metrics.metrics_client.start }
    end

    def workers
      @workers
    end

    def make_remained_job
      @status = STATUSES[:terminating]
      Stackify.msgs_queue.push_remained_msgs
    end

    def is_valid?
      configuration.is_valid?
    end

    def terminating?
      @status == STATUSES[:terminating]
    end

    def terminated?
      @status == STATUSES[:terminated]
    end

    def working?
      @status == STATUSES[:working]
    end

    def status= status
      if STATUSES.has_value? status
        @status = status
      else
        raise "method 'status=' should get one of arguments #{STATUSES.values}, not a #{status}"
      end
    end
  end

end

require 'stackify/engine' if defined? Rails
