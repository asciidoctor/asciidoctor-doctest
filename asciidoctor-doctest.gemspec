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

  s.files         = Dir['data/**/*', 'lib/**/*', '*.gemspec', 'CHANGELOG*', 'LICENSE*', 'README*']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.7'

  # runtime
  s.add_runtime_dependency 'asciidoctor', '>= 1.5.0', '< 3.0'
  s.add_runtime_dependency 'corefines', '~> 1.2'
  s.add_runtime_dependency 'diffy', '~> 3.0'
  s.add_runtime_dependency 'htmlbeautifier', '~> 1.0'
  s.add_runtime_dependency 'minitest', '~> 5.25'
  s.add_runtime_dependency 'nokogiri', '~> 1.14.0'

  # development
  s.add_development_dependency 'bundler', '>= 1.6'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'thread_safe', '~> 0.3'
  s.add_development_dependency 'yard', '~> 0.9'

  # unit tests
  s.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
  s.add_development_dependency 'fakefs', '~> 1.2'
  s.add_development_dependency 'ostruct', '~> 0.6'
  s.add_development_dependency 'simplecov', '~> 0.17.1'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rspec-collection_matchers', '~> 1.1'

  # integration tests
  s.add_development_dependency 'aruba', '~> 1.0'
  s.add_development_dependency 'cucumber', '~> 3.0'
  s.add_development_dependency 'slim', '~> 4.0'
end
