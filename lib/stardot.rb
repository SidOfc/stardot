# frozen_string_literal: true

require_relative 'stardot/version'
require_relative 'stardot/fragment'

module Stardot
  # run a block or use the default file located in spec
  def self.configure(&block)
    unless block_given?
      stardot_rb = File.read File.join(__dir__, '../spec/files/stardot.rb')
      block      = proc { instance_eval stardot_rb  }
    end

    Fragment.new(&block)
  end

  def self.configure!(&block)
    fragment = configure(&block)
    fragment.process
    fragment
  end

  def self.log
    @log ||= []
  end
end
