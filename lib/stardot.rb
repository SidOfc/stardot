# frozen_string_literal: true

require 'yaml'
require 'paint'
require_relative 'stardot/version'
require_relative 'stardot/proxy'
require_relative 'stardot/logger'
require_relative 'stardot/fragment'

module Stardot
  def self.configure(&block)
    unless block_given?
      stardot_rb = File.read File.join(__dir__, '../spec/files/stardot.rb')
      block      = proc { instance_eval stardot_rb }
    end

    Fragment.new({ proxy: false }, &block)
  end

  def self.configure!(&block)
    fragment = configure(&block)
    fragment.process
    logger.persist
    fragment
  end

  def self.logger
    @logger ||= Logger.new "log/stardot.#{Time.now.to_i}.log"
  end
end
