# frozen_string_literal: true

module Stardot
  class Fragment
    STATUSES       = %i[ok error].freeze
    LAZY_LOAD_ROOT =
      File.join(File.expand_path(__dir__), 'fragments/**/fragment.rb').freeze

    COLORS = {
      ok: :green,
      error: :red,
      action: :default
    }.freeze

    def initialize(**opts, &block)
      @block       = block
      @label       = self.class.name.gsub('::', '_').downcase.to_sym.freeze
      @last_action = nil

      if opts[:proxy] != false
        @proxy = Proxy.new(self, before: method(:before_action),
                                 after: method(:after_action))
      end

      setup if respond_to? :setup
    end

    def process
      (@proxy || self).instance_eval(&@block) if @block
    end

    def self.lazy_loadable
      @lazy_loadable ||= Dir.glob(LAZY_LOAD_ROOT).map do |path|
        [path.split('/')[-2].to_s.to_sym, path]
      end.to_h
    end

    def self.inherited(fragment_class)
      define_method fragment_class.name.downcase do |*args, &block|
        fragment_class.new(*args, &block).process
      end
    end

    def self.current_indent
      @current_indent ||= +''
    end

    def self.indent!(amount = 2)
      @current_indent << ' ' * (@last_amount = amount)
    end

    def self.unindent!(amount = @last_amount)
      @current_indent = current_indent[0..-(amount + 1)]
    end

    private

    def method_missing(name, *args, &block)
      return super if Fragment.lazy_loadable[name].nil?

      require Fragment.lazy_loadable[name]
      send(name, *args, &block)
    end

    def respond_to_missing?(name, *)
      !Fragment.lazy_loadable[name].nil?
    end

    STATUSES.each do |status|
      define_method status do |message = nil|
        echo message, status if message&.is_a?(String)
        status
      end
    end

    def echo(message, color = :default)
      painted = Paint[message, COLORS.fetch(color, color)]

      $stdout.puts "#{Fragment.current_indent}#{painted}"
    end

    def before_action(name, *_args)
      echo "#{@label}::#{name}", :action \
        unless @last_action == name || Fragment.lazy_loadable[name]

      Fragment.indent!
    end

    def after_action(name, *args, result)
      @last_action = name

      Fragment.unindent!
      Stardot.logger.append(
        fragment: @label, action: name,
        args: args, result: result
      )
    end
  end
end
