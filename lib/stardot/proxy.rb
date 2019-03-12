# frozen_string_literal: true

module Stardot
  class Proxy
    def initialize(target, **opts)
      @target = target
      @before = opts[:before]
      @after  = opts[:after]
    end

    # rubocop:disable Style/MethodMissingSuper
    def method_missing(name, *args, &block)
      @before&.call(name, *args)
      @after&.call(name, *args, @target.send(name, *args, &block))
    end
    # rubocop:enable Style/MethodMissingSuper

    def respond_to_missing?(name, *args)
      @target.respond_to?(name, *args)
    end
  end
end
