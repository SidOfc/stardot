# frozen_string_literal: true

module Stardot
  class Fragment
    def initialize(&block)
      @block = block
    end

    def process
      instance_eval(&@block) if @block
    end

    def self.inherited(plugin_class)
      define_method plugin_class.name.downcase do |*args, &block|
        plugin_class.decorated(*args, &block).process
      end
    end

    def self.decorated(*args, &block)
      plugin  = new(*args, &block)
      actions = plugin.class.instance_methods(false) - Object.instance_methods

      actions.each do |action|
        original_action_name = "original_#{action}"

        plugin.class.alias_method original_action_name, action
        plugin.class.instance_eval { private original_action_name }

        plugin.class.define_method action do |*args, &block|
          Stardot.log << ({
            action: action,
            plugin: self.class.name.downcase.to_sym,
            result: send(original_action_name, *args, &block)
          })
        end
      end

      plugin
    end
  end
end
