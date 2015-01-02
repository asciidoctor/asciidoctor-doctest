require 'aruba'
require 'aruba/cucumber'
require 'asciidoctor/doctest'
require 'fileutils'
require 'rspec/expectations'

Dir["#{__dir__}/../step_definitions/**/*.rb"].each { |file| require file }

PROJECT_DIR  = File.expand_path('../../', __dir__)
FIXTURES_DIR = File.expand_path('../fixtures', __dir__)
TEMP_DIR     = File.join(PROJECT_DIR, 'tmp/aruba')

Before do
  FileUtils.mkdir_p TEMP_DIR
  # overwrite Aruba's default temp directory location
  @dirs = [TEMP_DIR]

  # Increase timeout for JRuby, that is very slooow...
  @aruba_timeout_seconds = 50
end

After do
  FileUtils.rm_rf(TEMP_DIR) if Dir.exist? TEMP_DIR
end
