# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hakossh/version'

Gem::Specification.new do |spec|
  spec.name          = 'hakossh'
  spec.version       = Hakossh::VERSION
  spec.authors       = ['wata']
  spec.email         = ['shinya-watanabe@cookpad.com']

  spec.summary       = %q{AWS + SSH for hako apps}
  spec.description   = %q{AWS + SSH for hako apps}
  spec.homepage      = 'https://ghe.ckpd.co/shinya-watanabe/hakossh'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gems.ckpd.co'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'peco_selector', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
end
