# frozen_string_literal: true

module Stardot
  class Plugin
    attr_reader :steps

    def initialize(*_args, **_opts, &block)
      @steps = {}
      @step  = nil

      wrap_methods! unless self.class.name == 'Stardot::Plugin'

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
    alias_method :ln, :symlink

    def method_missing(name, *args, **opts, &block)
      raise Stardot::Error.new("Plugin: #{name} not found, aborting") \
        unless Stardot.plugin? name

      plugin(name, *args, **opts, &block)
    end

    def self.inherited(plugin)
      Stardot.plugins << plugin
    end

    def wrap_methods!
      (self.class.instance_methods(false) - Object.instance_methods).each do |mtd|
        # set wrapped alias to something that is 'hard' to accidentally
        # overwrite or call. Since the alias name will always contain
        # a '-' character, only #send can be used to invoke the alias.
        wrapped_mtd_name = "wrapped-#{mtd}"

        self.class.alias_method wrapped_mtd_name, mtd
        self.class.define_method mtd do |*args, &block|
          step(mtd) { send wrapped_mtd_name, *args, &block }
        end
      end
    end
  end
end

