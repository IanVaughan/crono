module Crono
  # Crono::PerformerProxy is a proxy used in cronotab.rb semantic
  class PerformerProxy
    def initialize(performer, scheduler)
      @performer = performer
      @scheduler = scheduler
    end

    def every(period, *args)
      job = Job.new(@performer, Period.new(period, *args))
      @scheduler.add_job(job)
    end
  end

  def self.perform(performer)
    pp = PerformerProxy.new(performer, Crono.scheduler)
    pp.every(*performer.every) if performer.respond_to?(:every)
    pp
  end
end
