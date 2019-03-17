# frozen_string_literal: true

require 'bundler/setup'
require 'stardot'

module Helpers
  ROOT = File.join __dir__, 'files'

  def fragment(**opts, &block)
    Stardot::Fragment.new(opts.merge(silent: true), &block).process
  end

  def as_plugin(name, &block)
    return fragment.send name unless block

    fragment { send(name, &block) }
  end

  def with_cli_args(*args)
    original_size = ARGV.size
    ARGV.concat args
    yield if block_given?
    ARGV.slice!(original_size..-1)
  end
end

RSpec.configure do |config|
  config.include Helpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
