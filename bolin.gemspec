# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bolin/version'

Gem::Specification.new do |spec|
  spec.name          = "bolin"
  spec.version       = Bolin::VERSION
  spec.authors       = ["Yuya Takeyama"]
  spec.email         = ["sign.of.the.wolf.pentagram@gmail.com"]

  spec.summary       = %q{Framework for LINE BOT API}
  spec.description   = %q{Framework for LINE BOT API}
  spec.homepage      = "https://github.com/yuya-takeyama/bolin"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
