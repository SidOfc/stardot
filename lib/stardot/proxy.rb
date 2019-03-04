# frozen_string_literal: true

module Stardot
  class Proxy
    attr_reader :target
    def initialize(target, **opts)
      @target = target
      @before = opts[:before]
      @after  = opts[:after]
    end

    def method_missing(name, *args, &block)
      return super unless target.respond_to? name

      @before&.call(name, *args)
      @after&.call(name, *args, target.send(name, *args, &block))
    end

    def respond_to_missing?(name, *args)
      target.respond_to_missing?(name, *args)
    end
  end
end
