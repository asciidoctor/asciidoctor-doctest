require 'rake/clean'
require 'bundler/gem_tasks'

default_tasks = []

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :test => :spec
  default_tasks << :spec
rescue LoadError => e
  warn "#{e.path} is not available"
end

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = ['-r features/support', '--format pretty']
  end

  default_tasks << :cucumber
rescue LoadError => e
  warn "#{e.path} is not available"
end

begin
  require 'yard'
  # options are defined in .yardopts
  YARD::Rake::YardocTask.new(:yard)
rescue LoadError => e
  warn "#{e.path} is not available"
end

task :default => default_tasks
