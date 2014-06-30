# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'edmunds/chef/proxy/version'

Gem::Specification.new do |spec|
  spec.name          = "edmunds-chef-proxy"
  spec.version       = Edmunds::Chef::Proxy::VERSION
  spec.authors       = ["Dmitriy Vinogradov"]
  spec.email         = ["dvinogradov@edmunds.com"]
  spec.summary       = %q{Edmunds Chef proxy}
  spec.description   = %q{Additinal Chef functionality for Edmunds}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "em-proxy", "~> 0.1", ">= 0.1.8"
  spec.add_dependency "mixlib-authentication"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
end
