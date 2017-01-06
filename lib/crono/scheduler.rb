module Crono
  # Scheduler is a container for job list and queue
  class Scheduler
    attr_accessor :jobs

    def initialize
      self.jobs = []
      @jobs = load_jobs
    end

    def load_jobs
      Crono::CronoJob.map.each do |j|
        Job.new(j.performer.to_const)
      end
    end

    # rename #add
    def add_job(job)
      job.load
      jobs << job
    end

    def find(job)
      jobs.any? job
    end

    def has_job?(job)
      !!find(job)
    end

    def next
      queue.first
    end

    private

    def queue
      jobs.sort_by(&:next)
    end
  end

  mattr_accessor :scheduler
end
