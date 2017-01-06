# cronotab.rb - Crono configuration file
#
# Here you can specify periodic jobs and schedule.
# You can use ActiveJob's jobs from `app/jobs/`
# You can use any class. The only requirement is that
# class should have a method `perform` without arguments.
#
class TestJob
  def perform
    puts 'Test!'
  end
end

Crono.perform(TestJob).every 2.days, at: '15:30'


class TestJobbWithModule
  include Crono::Performer

  def perform
    puts 'Test!'
  end

  # could include this here. but doesnt allow changed id
  # for many instances of same class with different schedules
  # but can't really do that if not creating via cronotab with .every
  def job_id
  end

  # optional. if not present Job will create use the schedule
  # as defined in the DB record for the job. (which will be configable via the sinatra app, or your own)
  # if the job has no schedule data (i.e. on first creation) it polls every second (actaully uses internal schedule)
  # until its defined before the job runs
  def self.every
    [2.days, at: '12:11']
    # OR create an array of periods to create many instances of this job
    # [[2.days, at: '12:11']
    #  [2.days, at: '12:11']]
  end
end



class TestJob3
  def perform
    puts 'Test!'
  end

  def every
    [2.days, at: '12:11']
  end
end

Crono.perform(TestJob)

Crono::PerformerProxy.new(TestJob, Crono.scheduler)
