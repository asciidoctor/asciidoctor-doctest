# coding: utf-8
require File.expand_path('lib/asciidoctor/doctest/version', __dir__)

Gem::Specification.new do |s|
  s.name          = 'asciidoctor-doctest'
  s.version       = Asciidoctor::DocTest::VERSION
  s.author        = 'Jakub Jirutka'
  s.email         = 'jakub@jirutka.cz'
  s.homepage      = 'https://github.com/asciidoctor/asciidoctor-doctest'
  s.license       = 'MIT'

  s.summary       = 'Test suite for Asciidoctor backends'
  s.description   = <<-EOS
A tool for end-to-end testing of Asciidoctor backends based on comparing of textual output.
  EOS

  begin
    s.files       = `git ls-files -z -- */* {CHANGELOG,LICENSE,Rakefile,README}*`.split("\x0")
  rescue
    s.files       = Dir['**/*']
  end
  s.executables   = s.files.grep(/^bin\//) { |f| File.basename(f) }
  s.test_files    = s.files.grep(/^(test|spec|features)\//)

  s.require_paths = ['lib']
  s.has_rdoc      = 'yard'

  s.required_ruby_version = '>= 2.0'

  # runtime
  s.add_runtime_dependency 'asciidoctor', '~> 1.5.0'
  s.add_runtime_dependency 'colorize', '~> 0.6'
  s.add_runtime_dependency 'corefines', '~> 1.0.0'
  s.add_runtime_dependency 'diffy', '~> 3.0'
  s.add_runtime_dependency 'htmlbeautifier', '~> 1.0'
  s.add_runtime_dependency 'minitest', '~> 5.4'
  s.add_runtime_dependency 'minitest-rg', '~> 5.1'  # optional
  # Avoid versions >=1.6.4 and <1.6.6
  s.add_runtime_dependency 'nokogiri', '~> 1.6.0'

  # development
  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'thread_safe', '~> 0.3'
  s.add_development_dependency 'yard', '~> 0.8'

  # unit tests
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4'
  s.add_development_dependency 'fakefs', '~> 0.6.4'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.1'

  # integration tests
  s.add_development_dependency 'aruba', '~> 0.6'
  s.add_development_dependency 'cucumber', '~> 1.3'
  s.add_development_dependency 'slim', '~> 2.1'
end
