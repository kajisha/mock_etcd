# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mock_etcd/version'

Gem::Specification.new do |spec|
  spec.name          = 'mock_etcd'
  spec.version       = MockEtcd::VERSION
  spec.authors       = ['kajisha']
  spec.email         = ['kajisha@gmail.com']
  spec.summary       = %q{mock etcd-ruby}
  spec.description   = %q{mock etcd-ruby}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'etcd'
  spec.add_runtime_dependency 'webmock'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
end