# frozen_string_literal: true

require 'etc'
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
    log_file = opts.fetch :log_file, logger.path
    frag     = configure(&block).process

    logger.persist log_file if frag.opts[:log] == true || opts[:log] == true
    frag
  end

  def self.logger
    @logger ||= Logger.new
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

  def self.cores
    Etc.nprocessors
  end
end

system 'stty -echoctl'
trap('SIGINT') { Stardot.kill }
