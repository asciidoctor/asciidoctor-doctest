require 'bundler/gem_tasks'

default_tasks = []

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :test => :spec
  default_tasks << :spec
rescue LoadError
  warn 'no rspec available'
end

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = ['-r features/support', '--format pretty']
  end

  default_tasks << :cucumber
rescue LoadError
  warn 'no cucumber available'
end

task :default => default_tasks
