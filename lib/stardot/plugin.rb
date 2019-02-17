# frozen_string_literal: true

module Stardot
  class Plugin < DSL
    def self.inherited(by)
      Stardot.plugins << by
      puts "registered plugin #{by.name}"
    end

    def self.define_step(step, &block)
      define_method step do |*args, **opts|
        step(:install) { block.call(*args, **opts) }
      end
    end

    def self.method_missing(sym, *args, **opts, &block)
      define_step sym, &block
    end
  end
end

