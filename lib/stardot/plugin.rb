# frozen_string_literal: true

module Stardot
  class Plugin < DSL
    def self.inherited(plugin)
      Stardot.plugins << plugin
    end

    def self.define_step(step_name, &block)
      define_method step_name do |*args, **opts|
        step(step_name) { block.call(*args, **opts) }
      end
    end

    def self.method_missing(sym, *args, **opts, &block)
      define_step sym, &block
    end
  end
end

