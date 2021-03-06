# frozen_string_literal: true

require 'bundler/setup'
require 'stardot'

Stardot.sync!

module Helpers
  ROOT_DIR = File.join __dir__, 'files'

  def git_branch(working_directory)
    command = [
      "git -C #{File.expand_path(working_directory)} branch",
      "grep '*'",
      "cut -d' ' -f2"
    ].join ' | '

    `#{command}`.strip
  end

  def one_of(*any)
    any.sample
  end

  def reply_with(input, frag = fragment, &block)
    with_cli_args '-i' do
      allow(frag.printer).to receive(:read_input_char).and_return(input)
      frag.instance_eval(&block)
    end
  end

  def statuses
    Stardot.logger.entries.map { |entry| entry[:status] }
  end

  def fragment(**opts, &block)
    Stardot::Fragment.new(opts.merge(silent: true, log: true), &block).process
  end

  def create_plugin(name)
    classified = name.to_s.capitalize.gsub(/_(.)/) do
      Regexp.last_match(1).upcase
    end

    # rubocop:disable Security/Eval
    eval "class #{classified} < Stardot::Fragment; end",
         TOPLEVEL_BINDING, __FILE__, __LINE__ - 1
    # rubocop:enable Security/Eval
  end

  def as_plugin(name, &block)
    return fragment.send name unless block

    fragment { send(name, &block) }
  end

  def with_cli_args(*args)
    original_size = ARGV.size
    ARGV.concat args
    result = yield if block_given?
    ARGV.slice!(original_size..-1)
    result
  end
end

RSpec.configure do |config|
  config.include Helpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
