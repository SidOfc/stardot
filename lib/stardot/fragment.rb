# frozen_string_literal: true

module Stardot
  class Fragment
    STATUSES       = %i[ok error info warn].freeze
    LAZY_LOAD_ROOT =
      File.join(File.expand_path(__dir__), 'fragments/**/fragment.rb').freeze

    def initialize(**opts, &block)
      @block       = block
      @label       = self.class.name.gsub('::', '_').downcase.to_sym
      @async_tasks = []
      @tasks_total = 0
      @printer     = Printer.new

      if opts[:proxy] != false
        @proxy = Proxy.new(self, before: method(:before_action),
                                 after: method(:after_action))
      end

      setup if respond_to? :setup
    end

    def async(&block)
      @async_tasks << Thread.new do
        instance_eval(&block)
      end
    end

    def process
      @ts = Time.now.to_i
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

    def method_missing(name, *args, &block)
      return super if Fragment.lazy_loadable[name].nil?

      require Fragment.lazy_loadable[name]
      send(name, *args, &block)
    end

    def respond_to_missing?(name, *_args)
      !Fragment.lazy_loadable[name].nil?
    end

    private

    STATUSES.each do |status|
      define_method status do |message = nil, **opts|
        return unless message

        @printer.echo message, **{ color: status }.merge(opts)
        status
      end
    end

    def time_passed
      diff_time = Time.at(Time.now.to_i - @ts).utc
      format '%02d:%02d:%02d', diff_time.hour, diff_time.min, diff_time.sec
    end

    def before_action(name, *_args)
      @printer.echo "#{@label}::#{name}", color: :action \
        unless @last_action == name || Fragment.lazy_loadable[name]

      @printer.indent
    end

    def after_action(name, *args, result)
      @last_action = name

      wait_for_async_tasks
      @printer.unindent

      Stardot.logger.append(
        fragment: @label, action: name,
        args: args, result: result
      )
    end

    def update_progress
      @printer.tick!
      load_frame = @printer.paint @printer.loader, :info
      suffix     = @printer.paint 'finished', :info
      counters   = @printer.paint(
        "#{@tasks_total - (@async_tasks.count - 1)}/#{@tasks_total}",
        :gray
      )

      @printer.echo "#{load_frame} #{counters} #{suffix}", soft: 1
    end

    def wait_for_async_tasks
      @tasks_total = (@async_tasks.count - 1).freeze

      while @async_tasks.any?(&:status)
        @async_tasks.reject(&:status).each(&:join)
        @async_tasks = @async_tasks.select(&:status)

        update_progress
        sleep 1.0 / 30
      end

      @printer.reset!
    end
  end
end
