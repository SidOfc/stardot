# frozen_string_literal: true

require 'stardot/version'
require 'stardot/plugin'

module Stardot
  class Error < StandardError; end

  SKIP_FLAGS = ARGV.select { |arg| arg.start_with? '--skip-' }
                   .map { |skip| skip.split(/^--skip-/).pop.downcase }.freeze
  ONLY_FLAGS = ARGV.select { |arg| arg.start_with? '--only-' }
                   .map { |skip| skip.split(/^--only-/).pop.downcase }.freeze

  def self.configure_using_config_file!
    configure do
      instance_eval File.read(File.join(__dir__, '../spec/files/stardot.rb'))
    end
  end

  def self.configure(&block)
    runner = Plugin.new(&block)

    runner.steps.each do |name, steps|
      steps.each(&:call)
    end

    runner
  end

  def self.execute_plugin?(name)
    return true if !plugin?(name) || ONLY_FLAGS.any? { |flag| flag == name }

    ONLY_FLAGS.empty? && SKIP_FLAGS.none? { |flag| flag == name }
  end

  def self.plugin?(name)
    plugins.any? { |p| p.name.downcase == name.to_s.downcase }
  end

  def self.plugins
    @plugins ||= []
  end
end
