# frozen_string_literal: true

require 'stardot/version'
require 'stardot/dsl'
require 'stardot/plugin'

module Stardot
  class Error < StandardError; end

  def self.configure(&block)
    runner = DSL.new(&block)

    runner.steps.each do |name, steps|
      steps.map(&:call)
    end

    runner
  end

  def self.plugin?(name)
    plugins.any? { |p| p.name.downcase == name.to_s.downcase }
  end

  def self.plugins
    @plugins ||= []
  end
end
