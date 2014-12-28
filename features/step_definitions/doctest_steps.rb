require 'fileutils'

Given 'I do have a template-based HTML backend with DocTest' do
  FileUtils.cp_r Dir.glob("#{FIXTURES_DIR}/html-slim/**"), TEMP_DIR
end
