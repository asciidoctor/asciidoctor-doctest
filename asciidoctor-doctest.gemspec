# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'asciidoctor/doctest/version'

Gem::Specification.new do |s|
  s.name          = 'asciidoctor-doctest'
  s.version       = Asciidoctor::DocTest::VERSION
  s.date          = Time.now.strftime('%Y-%m-%d')
  s.author        = 'Jakub Jirutka'
  s.email         = 'jakub@jirutka.cz'
  s.homepage      = 'https://github.com/asciidoctor/asciidoctor-doctest'
  s.license       = 'MIT'

  s.summary       = 'Test suite for Asciidoctor backends'
  #s.description   = 'TODO'

  s.files         = `git ls-files -z -- */* {LICENSE,Rakefile,README}*`.split("\0") rescue Dir['**/*']
  s.executables   = s.files.grep(/^bin\//) { |f| File.basename(f) }
  s.test_files    = s.files.grep(/^(test|spec|features)\//)
  s.require_paths = ['lib']
  s.has_rdoc      = 'yard'
  s.extra_rdoc_files = ['LICENSE']

  s.required_ruby_version = '>= 2.0'

  s.add_development_dependency 'bundler', '~> 1.6'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'yard', '~> 0.8'

  s.add_runtime_dependency 'activesupport', '~> 3.1'
  s.add_runtime_dependency 'asciidoctor', '~> 1.5'
  s.add_runtime_dependency 'colorize', '~> 0.6'
  s.add_runtime_dependency 'diffy', '~> 3.0'
  s.add_runtime_dependency 'htmlbeautifier', '~> 0.0', '>= 0.0.10'
  s.add_runtime_dependency 'minitest', '~> 5.4'
  s.add_runtime_dependency 'nokogiri', '~> 1.6'

  # optional
  s.add_runtime_dependency 'minitest-rg', '~> 5.1'
end
