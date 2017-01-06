module Crono
  # Crono::PerformerProxy is a proxy used in cronotab.rb semantic
  class PerformerProxy
    def initialize(performer, scheduler)
      @performer = performer
      @scheduler = scheduler

      if performer.respond_to?(:every)
        period_from_class(performer.every)
      else
        period_from_db
      end
    end

    def every(period, *args)
      job = Job.new(performer, Period.new(period, *args))
      # Need to find and update or add, if .every is called
      # on a job already added via #period_from_db
      # So cannot schedule more than one job at the same time
      scheduler.delete(job) if schedule.has_job?(job)
      scheduler.add_job(job)
    end

    private

    attr_reader :performer, :scheduler

    def period_from_class(periods)
      if periods.first.is_a? Array
        periods.each { |p| every(*p) }
      else
        every(*periods)
      end
    end

    def period_from_db
      job = Job.new(performer)
      scheduler.add_job(job)
    end
  end

  def self.perform(performer)
    pp = PerformerProxy.new(performer, Crono.scheduler)
    # if performer.respond_to?(:every)
    #   pp.period_from_class(performer.every)
    # else
    #   pp.from_db
    # end
    pp
  end

  module Performer
    def self.included(base)
      # pp = PerformerProxy.new(base, Crono.scheduler)
      # if base.respond_to?(:every)
      #   pp.every(*base.every)
      # else
      #   pp.from_db
      # end
      Crono.perform(base)
    end
  end
end
