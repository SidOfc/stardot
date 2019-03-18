# frozen_string_literal: true

require 'yaml'
require 'json'
require 'io/console'
require 'paint'
require_relative 'stardot/version'
require_relative 'stardot/proxy'
require_relative 'stardot/logger'
require_relative 'stardot/printer'
require_relative 'stardot/fragment'

module Stardot
  def self.configure(&block)
    unless block_given?
      stardot_rb = File.read File.join(__dir__, '../spec/files/stardot.rb')
      block      = proc { instance_eval stardot_rb }
    end

    Fragment.new(&block)
  end

  def self.configure!(**opts, &block)
    fragment = configure(&block)
    fragment.process
    logger.persist unless opts[:log] == false
    fragment
  end

  def self.logger
    @logger ||= Logger.new "log/stardot.#{Time.now.to_i}.log"
  end

  def self.watch(*threads)
    (@watching ||= []).concat threads
  end

  def self.unwatch(*threads)
    @watching ||= []
    @watching -=  threads
    @watching
  end

  def self.kill
    @watching.each(&:kill)
    exit
  end
end

system 'stty -echoctl'
trap('SIGINT') { Stardot.kill }
