# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecsssh/version'

Gem::Specification.new do |spec|
  spec.name          = 'ecsssh'
  spec.version       = Ecsssh::VERSION
  spec.authors       = ['wata']
  spec.email         = ['wata.gm@gmail.com']

  spec.summary       = %q{AWS + SSH for ecs apps}
  spec.description   = %q{AWS + SSH for ecs apps}
  spec.homepage      = 'https://github.com/wata-gh/ecsssh'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 3'
  spec.add_dependency 'peco_selector', '~> 1.0'
  spec.add_dependency 'ox', '~> 2'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake', '~> 10.0'
end
