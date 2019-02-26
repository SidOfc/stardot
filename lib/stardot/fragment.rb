# frozen_string_literal: true

module Stardot
  class Fragment
    def initialize(&block)
      @block = block

      setup if respond_to? :setup
    end

    def process
      instance_eval(&@block) if @block
    end

    private

    def self.lazy_loadable
      @lazy_loadable ||= Dir.glob(File.join(
        File.expand_path(__dir__),
        'fragments/**/fragment.rb'
      )).map(&method(:explode_path)).to_h
    end

    def self.explode_path(path)
      [path.split('/')[-2].to_s.to_sym, path]
    end

    # lazy load fragments
    def method_missing(name, *args, &block)
      require Fragment.lazy_loadable[name]
      send(name, *args, &block)
    end

    def self.inherited(fragment_class)
      define_method fragment_class.name.downcase do |*args, &block|
        fragment_class.upgrade(*args, &block).process
      end
    end

    def self.upgrade(*args, &block)
      fragment = new(*args, &block)
      actions  = fragment.class.instance_methods(false) - Object.instance_methods

      actions.each do |action|
        original_action_name = "original_#{action}"

        fragment.class.instance_eval do
          alias_method  original_action_name, action
          define_method action do |*args, &block|
            Stardot.log << ({
              action:   action,
              fragment: self.class.name.downcase.to_sym,
              result:   send(original_action_name, *args, &block)
            })
          end
        end
      end

      fragment
    end
  end
end
