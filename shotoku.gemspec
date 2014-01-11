# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shotoku/version'

Gem::Specification.new do |spec|
  spec.name          = "shotoku"
  spec.version       = Shotoku::VERSION
  spec.authors       = ["Shota Fukumori (sora_h)"]
  spec.email         = ["her@sorah.jp"]
  spec.summary       = %q{Run scripts in multiple machines}
  spec.description   = %q{Run scripts in multiple machines.}
  spec.homepage      = "https://github.com/sorah/shotoku"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", "~> 1.4.4"
  spec.add_dependency "net-ssh", "~> 2.7.0"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14.1"
end
