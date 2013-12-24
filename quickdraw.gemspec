# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quickdraw/version'

Gem::Specification.new do |spec|
  spec.name          = "quickdraw"
  spec.version       = Quickdraw::VERSION
  spec.authors       = ["Bryan Morris"]
  spec.email         = ["bryan@internalfx.com"]
  spec.description   = %q{Quickly develop Shopify themes}
  spec.summary       = %q{Allows the use of ERB templates to develop and "compile" a theme and then automatically deploy to Shopify}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "listen"
  spec.add_development_dependency "celluloid"
  spec.add_development_dependency "httparty"
end
