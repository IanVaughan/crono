# This is an example of a good cronotab for tests

class TestJob
  def perform
    puts 'Test!'
  end
end

Crono.perform(TestJob).every 5.seconds

class TestJobWithEvery
  def perform
    puts 'Test!'
  end

  def every
    [5.seconds]
  end
end

Crono.perform(TestJobWithEvery)

class TestJobWithModule
  include Crono::Performer
  def perform
    puts 'Test!'
  end

  def every
    [5.seconds]
  end
end
