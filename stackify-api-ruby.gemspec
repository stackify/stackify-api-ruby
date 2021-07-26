# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stackify/version'

Gem::Specification.new do |spec|
  spec.name          = 'stackify-api-ruby'
  spec.version       = Stackify::VERSION
  spec.authors       = ['Stackify']
  spec.email         = ['support@stackify.com']
  spec.summary       = 'Stackify API for Ruby'
  spec.description   = 'Stackify Logs and Metrics API for Ruby'
  spec.homepage      = 'http://www.stackify.com/'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 1.9'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  if RUBY_PLATFORM == 'i386-mingw32'
    spec.add_development_dependency 'tzinfo-data'
  end

  spec.add_runtime_dependency 'faraday', '~> 0.8'
  spec.add_runtime_dependency 'net_http_unix', '~> 0.2'
end
