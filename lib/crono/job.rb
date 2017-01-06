require 'stringio'
require 'logger'

module Crono
  # Crono::Job represents a Crono job
  class Job
    include Logging

    attr_accessor :performer, :period, :last_performed_at, :job_log,
                  :job_logger, :healthy, :period_set

    def initialize(performer, period = nil)
      self.performer = performer
      self.period_set = true
      model.update(performer: performer)
      self.period = if period
                      model.update(period: period)
                      period
                    elsif period_in_db?
                      period_from_db
                    else
                      self.period_set = false
                      Period.new(1.second)
                    end
      self.job_log = StringIO.new
      self.job_logger = Logger.new(job_log)
      @semaphore = Mutex.new
    end

    def next
      next_time = period.next(since: last_performed_at)
      next_time.past? ? period.next : next_time
    end

    def description
      "Perform #{performer} #{period.description}"
    end

    def job_id
      # IRV maybe use performer and period, or a random uiid
      # need to persist this between cronic restarts so needs
      # to be const
      description
    end

    def perform
      log "Perform #{performer}"
      self.last_performed_at = Time.now

      Thread.new { perform_job }
    end

    def save
      @semaphore.synchronize do
        update_model
        clear_job_log
      end
    end

    def load
      self.last_performed_at = model.last_performed_at
    end

    private

    def clear_job_log
      job_log.truncate(job_log.rewind)
    end

    def update_model
      saved_log = model.reload.log || ''
      log_to_save = saved_log + job_log.string
      model.update(last_performed_at: last_performed_at,
                   log: log_to_save,
                   healthy: healthy)
    end

    def perform_job
      performer_instance = performer.new
      # performer_instance.instance_variable_set(:@_crono_job, self)
      if period_set
        performer_instance.perform
      elsif period_in_db?
        self.period = period_from_db
        self.period_set = true
      end
      finished_time_sec = format('%.2f', Time.now - last_performed_at)
    rescue StandardError => e
      handle_job_fail(e, finished_time_sec)
    else
      handle_job_success(finished_time_sec)
    ensure
      save
    end

    def handle_job_fail(exception, finished_time_sec)
      self.healthy = false
      log_error "Finished #{performer} in #{finished_time_sec} seconds"\
                "with error: #{exception.message}"
      log_error exception.backtrace.join("\n")
    end

    def handle_job_success(finished_time_sec)
      self.healthy = true
      log "Finished #{performer} in #{finished_time_sec} seconds"
    end

    def log_error(message)
      log(message, Logger::ERROR)
    end

    def log(message, severity = Logger::INFO)
      @semaphore.synchronize do
        logger.log severity, message
        job_logger.log severity, message
      end
    end

    def model
      @model ||= Crono::CronoJob.find_or_create_by(job_id: job_id)
    end

    def period_in_db?
      model.period && model.at
    end

    def period_from_db
      Period.new(model.period, model.at)
    end
  end
end
