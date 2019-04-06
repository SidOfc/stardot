# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stardot/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.3'
  spec.name          = 'stardot'
  spec.version       = Stardot::VERSION
  spec.authors       = ['Sidney Liebrand']
  spec.email         = ['sidneyliebrand@gmail.com']

  spec.summary       = 'Yet another one of those dotfile managers, sorry :P'
  spec.homepage      = 'https://github.com/SidOfc/stardot'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been
  # added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.start_with? 'spec' }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'paint'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-coolline'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
