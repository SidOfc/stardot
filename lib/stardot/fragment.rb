# frozen_string_literal: true

module Stardot
  class Fragment
    attr_reader :id, :printer, :opts

    STATUSES       = %i[ok error info warn].freeze
    LAZY_LOAD_ROOT =
      File.join(File.expand_path(__dir__), 'fragments/**/fragment.rb').freeze

    def initialize(**opts, &block)
      @id          = self.class.name.gsub('::', '_').downcase.to_sym
      @opts        = opts
      @block       = block
      @printer     = Printer.new(**opts)
      @tasks       = []
      @queue       = []
      @workers     = opts.fetch :workers, Stardot.cores
      @tasks_count = 0

      setup if respond_to? :setup
    end

    def async(&block)
      @queue << lambda do
        return instance_eval(&block) if @workers < 2

        Thread.new { instance_eval(&block) }
      end
    end

    def process(&block)
      blk = block || @block
      @ts = Time.now.to_i

      instance_eval(&self.class.prerequisites.shift) \
        until self.class.prerequisites.empty?

      instance_eval(&blk) if blk

      wait_for_tasks

      self
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
      @interactive ||=
        STDIN.isatty &&
        @opts.fetch(:interactive, any_flag?('-i', '--interactive'))
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
      Time.at(Time.now.to_i - initial_time).utc
    end

    def progress(**opts)
      done  = @queue.empty? && @tasks.empty?
      parts = done ? progress_finished_parts : progress_running_parts
      parts << progress_text(done, **opts)

      printer.echo parts.join(' '),
                   soft: done ? !opts.fetch(:sticky, false) : true
    end

    def progress_text(done = false, **opts)
      text = opts.fetch :text, done ? @done_label : @progress_label

      if done
        @done_label     = nil
        @progress_label = nil
      end

      printer.paint text || 'finished', color: done ? :ok : :warn
    end

    def progress_label(label, done_label = nil)
      @done_label     ||= done_label
      @progress_label ||= label
    end

    def progress_running_parts
      [printer.paint(printer.loader,       color: :warn),
       printer.paint(progress_time_passed, color: :gray),
       printer.paint(progress_so_far,      color: :warn)]
    end

    def progress_finished_parts
      [printer.paint(printer.done,         color: :ok),
       printer.paint(progress_time_passed, color: :default),
       printer.paint(progress_so_far,      color: :ok)]
    end

    def progress_time_passed
      dt = time_passed @start

      "[#{format('%02d:%02d:%02d', dt.hour, dt.min, dt.sec)}]"
    end

    def progress_so_far
      finished = @tasks_count - @queue.count - @tasks.count

      "#{finished}/#{@tasks_count}"
    end

    def load_while(msg = 'finished', **opts, &block)
      async(&block)
      wait_for_tasks(**opts, text: msg)
    end

    def consume_queue
      while @queue.any? && @tasks.size < @workers
        worker = @queue.shift.call

        next unless worker.is_a? Thread

        @tasks << worker
        Stardot.watch worker
      end
    end

    def clear_finished_tasks
      done    = @tasks.reject(&:status)
      @tasks -= done

      Stardot.unwatch(*done)
      done.each(&:join)
    end

    def wait_for_tasks(**opts)
      @tasks_count = @queue.count
      @start       = Time.now.to_i

      printer.reset!
      consume_queue

      while @tasks.any?
        clear_finished_tasks
        consume_queue
        progress(**opts)
        sleep 1.0 / 30
      end
    end

    class << self
      def async(mtd)
        unbound_original_mtd = instance_method mtd

        define_method mtd do |*args, &block|
          async { unbound_original_mtd.bind(self).call(*args, &block) }
        end
      end

      def mtd_or_proc(mtd = nil, &block)
        block = proc { send mtd } if mtd && block.nil?
        block
      end

      def missing_file(path, mtd = nil, &block)
        path = File.expand_path path

        return path if File.exist? path

        prerequisites << mtd_or_proc(mtd, &block)
      end

      def missing_binary(cmd, mtd = nil, &block)
        return cmd if which cmd

        prerequisites << mtd_or_proc(mtd, &block)
      end

      def prerequisites
        @prerequisites ||= []
      end

      def lazy_loadable
        @lazy_loadable ||= Dir.glob(LAZY_LOAD_ROOT).map do |path|
          [path.split('/')[-2].to_s.to_sym, path]
        end.to_h
      end

      def inherited(fragment_class)
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
    end
  end
end
