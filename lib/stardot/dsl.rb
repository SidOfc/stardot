# frozen_string_literal: true

module Stardot
  class DSL
    attr_reader :steps

    def initialize(*_args, **_opts, &block)
      @steps = {}
      @step  = nil

      instance_eval(&block) if block
    end

    def step(name, &block)
      @step = name.to_s
      @steps[@step] ||= []
      @steps[@step] << block if block

      @step = nil
    end

    def expand_path(target)
      return target if target.start_with? '/'

      File.join Dir.home, target.gsub('~', '')
    end

    def plugin(name, *args, **opts, &block)
      found = Stardot.plugins.find { |c| c.name.downcase == name.to_s.downcase }

      step(name) do
        found
          .new(*args, **opts, &block)
          .steps
          .map { |name, steps| steps.map(&:call) }
      end
    end

    def symlink(from, to = '~')
      from = expand_path from
      to   = expand_path to

      step(:symlink) { puts "symlink: #{from} ~> #{to}" }
    end

    def method_missing(name, *args, **opts, &block)
      raise Stardot::Error.new("Plugin: #{name} not found, aborting") \
        unless Stardot.plugin? name

      plugin(name, *args, **opts, &block)
    end
  end
end

