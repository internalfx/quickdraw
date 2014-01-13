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
  spec.homepage      = "https://github.com/internalfx/quickdraw"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10"

  spec.add_runtime_dependency "thor", "~> 0.18"
  spec.add_runtime_dependency "filewatcher", "~> 0.3"
  spec.add_runtime_dependency "celluloid", "~> 0.15"
  spec.add_runtime_dependency "httparty", "~> 0.12"
  spec.add_runtime_dependency "filepath", "~> 0.6"
end
