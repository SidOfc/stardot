# frozen_string_literal: true

module Stardot
  class Fragment
    attr_reader :id, :printer, :opts

    STATUSES       = %i[ok error info warn].freeze
    LAZY_LOAD_ROOT =
      File.join(File.expand_path(__dir__), 'fragments/**/fragment.rb').freeze

    def initialize(**opts, &block)
      @id                = self.class.name.gsub('::', '_').downcase.to_sym
      @opts              = opts
      @block             = block
      @printer           = Printer.new(**opts)
      @async_tasks       = []
      @async_queue       = []
      @workers           = opts.fetch :workers, Stardot.cores
      @async_tasks_count = 0

      setup if respond_to? :setup
    end

    def async(&block)
      @async_queue << proc { Thread.new { instance_eval(&block) } }
    end

    def process(&block)
      blk = block || @block
      @ts = Time.now.to_i

      instance_eval(&self.class.prerequisites.shift) until self.class.prerequisites.empty?

      instance_eval(&blk) if blk

      wait_for_async_tasks

      self
    end

    def self.mtd_or_proc(mtd = nil, &block)
      block = proc { send mtd } if mtd && block.nil?
      block
    end

    def self.missing_file(path, mtd = nil, &block)
      path = File.expand_path path

      return path if File.exist? path

      prerequisites << mtd_or_proc(mtd, &block)
    end

    def self.missing_binary(cmd, mtd = nil, &block)
      return cmd if which cmd

      prerequisites << mtd_or_proc(mtd, &block)
    end

    def self.prerequisites
      @prerequisites ||= []
    end

    def self.lazy_loadable
      @lazy_loadable ||= Dir.glob(LAZY_LOAD_ROOT).map do |path|
        [path.split('/')[-2].to_s.to_sym, path]
      end.to_h
    end

    def self.inherited(fragment_class)
      fragment_name = fragment_class.name.split(/(?=[[:upper:]])/)
                                    .map(&:downcase).join('_')

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

    def interactive?
      @interactive ||= STDIN.isatty && @opts.fetch(:interactive, any_flag?('-i', '--interactive'))
    end

    def run_silent(cmd)
      system "#{cmd} >/dev/null 2>&1"
    end

    def prompt(msg, options, **opts)
      printer.prompt(msg, options, **opts)
    end

    STATUSES.each do |status|
      define_method status do |message = '', **opts|
        printer.echo(message, **{ color: status }.merge(opts))

        if @opts[:log]
          Stardot.logger.append fragment: id, status: status, message: message
        end

        status
      end
    end

    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

      ENV['PATH'].split(File::PATH_SEPARATOR).find do |path|
        exts.find do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
    end

    private

    def any_flag?(*flags)
      flags.any?(&ARGV.method(:include?))
    end

    def time_passed(initial_time = @ts)
      diff_time = Time.at(Time.now.to_i - initial_time).utc
      format '%02d:%02d:%02d', diff_time.hour, diff_time.min, diff_time.sec
    end

    def progress(done = false, **opts)
      soft          = done ? !opts.fetch(:sticky, false) : true
      loader, color = done ? [printer.done, :warn] : [printer.loader, :info]
      load_frame    = printer.paint loader, color: color
      suffix        = printer.paint opts.fetch(:text, 'finished'), color: color

      timer    = printer.paint "[#{time_passed(@async_start)}]",
                               color: (done ? :default : :gray)
      counters = printer.paint(
        "#{@async_tasks_count - @async_queue.count - @async_tasks.count}/#{@async_tasks_count}",
        color: :gray
      )

      printer.echo "#{load_frame} #{timer} #{counters} #{suffix}", soft: soft
    end

    def show_loader(msg = 'finished', **opts, &block)
      async(&block)
      wait_for_async_tasks progress: { **opts, text: msg }
    end

    def consume_queue
      while @async_queue.any? && @async_tasks.size < @workers
        worker = @async_queue.shift.call

        @async_tasks << worker
        Stardot.watch worker
      end
    end

    def wait_for_async_tasks(**opts)
      return if (@async_tasks_count = @async_queue.count).zero?

      progress_opts = opts.fetch :progress, {}
      @async_start  = Time.now.to_i

      printer.reset!
      consume_queue

      while @async_tasks.any?
        done         = @async_tasks.reject(&:status)
        @async_tasks = @async_tasks.select(&:status)

        Stardot.unwatch(*done)
        done.each(&:join)

        consume_queue
        progress(false, **progress_opts)
        sleep 1.0 / 30
      end

      progress(true, **progress_opts)
    end
  end
end
