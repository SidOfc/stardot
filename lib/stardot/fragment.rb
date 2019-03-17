# frozen_string_literal: true

module Stardot
  class Fragment
    attr_reader :proxy, :id, :printer

    STATUSES       = %i[ok error info warn].freeze
    LAZY_LOAD_ROOT =
      File.join(File.expand_path(__dir__), 'fragments/**/fragment.rb').freeze

    def initialize(**opts, &block)
      @id                = self.class.name.gsub('::', '_').downcase.to_sym
      @opts              = opts
      @block             = block
      @printer           = Printer.new(**opts)
      @async_tasks       = []
      @async_tasks_count = 0

      unless self.class == Stardot::Fragment
        @proxy = Proxy.new self, after: method(:after_action)
      end

      setup if respond_to? :setup
    end

    def prompt(msg, options, **opts)
      answer     = nil
      default    = opts[:selected].to_s
      options    = options.map(&:to_s)
      print_opts = options.join '/'
      print_opts = print_opts.sub default, "[#{default}]" unless default.empty?

      warn "#{msg} (#{print_opts}): ", soft: opts[:soft], newline: false

      until options.include? answer
        answer = read_input_char
        answer = default if answer.empty?
      end

      warn '' # create a newline

      answer
    end

    def async(&block)
      worker = Thread.new { instance_eval(&block) }

      @async_tasks << worker
      Stardot.watch worker
    end

    def process(&block)
      blk = block || @block
      @ts = Time.now.to_i

      (@proxy || self).instance_eval(&blk) if blk

      self
    end

    def self.lazy_loadable
      @lazy_loadable ||= Dir.glob(LAZY_LOAD_ROOT).map do |path|
        [path.split('/')[-2].to_s.to_sym, path]
      end.to_h
    end

    def self.inherited(fragment_class)
      fragment_name = fragment_class.name.downcase
      define_method fragment_name do |*args, &block|
        printer.echo "★ #{fragment_name}", color: :action, style: :bold
        printer.indent
        instance = fragment_class.new(*args, **@opts, &block).process

        printer.unindent
        instance
      end
    end

    def method_missing(name, *args, &block)
      loadable = Fragment.lazy_loadable.delete name

      return super unless loadable

      require loadable
      send(name, *args, &block)
    end

    def respond_to_missing?(name, *_args)
      !Fragment.lazy_loadable[name].nil?
    end

    private

    STATUSES.each do |status|
      define_method status do |message = nil, **opts|
        return unless message

        printer.echo message, **{ color: status }.merge(opts)

        Stardot.logger.append(
          fragment: id, action: current_action, status: status
        )

        status
      end
    end

    def current_action(name = nil)
      @current_action = name if name
      @current_action
    end

    def interactive?
      @interactive ||= @opts.fetch(:interactive, STDIN.isatty && any_flag?('-i', '--interactive'))
    end

    def any_flag?(*flags)
      flags.find(&ARGV.method(:include?))
    end

    def read_input_char
      STDIN.getch.strip
    end

    def time_passed
      diff_time = Time.at(Time.now.to_i - @ts).utc
      format '%02d:%02d:%02d', diff_time.hour, diff_time.min, diff_time.sec
    end

    def before_action(name, *_args)
      current_action name
    end

    def after_action(name, *args, status)
      wait_for_async_tasks
      current_action nil
    end

    def progress(done = false)
      loader, color = done ? [printer.done, :warn] : [printer.loader, :info]
      load_frame = printer.paint loader, color: color
      suffix     = printer.paint 'finished', color: color
      counters   = printer.paint(
        "#{@async_tasks_count - @async_tasks.count}/#{@async_tasks_count}",
        color: :gray
      )

      printer.echo "#{load_frame} #{counters} #{suffix}", soft: 1
    end

    def wait_for_async_tasks
      return if (@async_tasks_count = @async_tasks.count).zero?

      printer.reset!

      while @async_tasks.any?
        done         = @async_tasks.reject(&:status)
        @async_tasks = @async_tasks.select(&:status)

        Stardot.unwatch(*done)
        done.each(&:join)

        progress
        sleep 1.0 / 30
      end

      progress true
    end
  end
end
