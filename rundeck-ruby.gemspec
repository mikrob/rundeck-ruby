# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rundeck-ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "rundeck-ruby"
  spec.version       = Rundeck::VERSION
  spec.authors       = ["Jon Phillips"]
  spec.email         = ["jphillips@biaprotect.com"]
  spec.description   = %q{Ruby client for Rundeck API}
  spec.summary       = %q{For talking to Rundeck}
  spec.homepage      = "https://github.com/jonp/rundeck-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.bindir        = 'exe'
  spec.executables   = `git ls-files -- exe/*`.split("\n").map{ |f| File.basename(f) }
  spec.add_runtime_dependency "rest-client", "~> 1.6"
  spec.add_runtime_dependency "json", "~> 1.8"
  spec.add_runtime_dependency "activesupport", "~> 3.0"
  spec.add_runtime_dependency "i18n", "~> 0.6"
  spec.add_runtime_dependency "naught", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.0"
end
