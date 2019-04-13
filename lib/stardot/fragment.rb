# frozen_string_literal: true

module Stardot
  class Fragment
    attr_reader :id, :printer, :queue, :opts

    STATUSES       = %i[ok error info warn].freeze
    LAZY_LOAD_ROOT =
      File.join(File.expand_path(__dir__), 'fragments/**/fragment.rb').freeze

    def initialize(**opts, &block)
      @id          = self.class.name.gsub('::', '_').downcase.to_sym
      @opts        = opts
      @block       = block
      @printer     = Printer.new(**opts)
      @queue       = Queue.new [], workers: opts[:workers]

      setup if respond_to? :setup
    end

    def async(&block)
      queue.add { instance_eval(&block) }
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
      @interactive ||= STDIN.isatty && any_flag?('-i', '--interactive')
    end

    def run_silent(cmd)
      bash "#{cmd} >/dev/null 2>&1"
    end

    def bash(cmd)
      `bash -c #{Shellwords.escape(cmd)}`
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

    private

    def any_flag?(*flags)
      flags.any?(&ARGV.method(:include?))
    end

    def time_passed(initial_time = @ts)
      Time.at(Time.now.to_i - initial_time).utc
    end

    def progress(**opts)
      parts = queue.clear? ? progress_finished_parts : progress_running_parts
      parts << progress_text(**opts)

      printer.echo parts.join(' '),
                   soft: queue.clear? ? !opts.fetch(:sticky, false) : true
    end

    def progress_text(**opts)
      text = opts.fetch :text, queue.clear? ? @done_label : @progress_label

      if queue.clear?
        @done_label     = nil
        @progress_label = nil
      end

      printer.paint text || 'finished', color: queue.clear? ? :ok : :warn
    end

    def progress_label(label, done_label = nil)
      @done_label     ||= done_label
      @progress_label ||= label
    end

    def progress_running_parts
      [printer.paint(printer.loader,                      color: :warn),
       printer.paint(progress_time_passed,                color: :gray),
       printer.paint("#{queue.completed}/#{queue.total}", color: :warn)]
    end

    def progress_finished_parts
      [printer.paint('★',                                 color: :ok),
       printer.paint(progress_time_passed,                color: :default),
       printer.paint("#{queue.completed}/#{queue.total}", color: :ok)]
    end

    def skip?(fragment_name)
      action_name = fragment_name.split(/(?=[[:upper:]_\-.])/)
                                 .map(&:downcase).join '_'

      return ARGV.any?(/^--only-#{action_name}/) if ARGV.any?(/^--only-\w+/)

      ARGV.any?(/^--skip-#{action_name}/)
    end

    def progress_time_passed
      "[#{format('%02d:%02d:%02d',
                 *time_passed(@start).instance_eval { [hour, min, sec] })}]"
    end

    def load_while(msg = 'finished', **opts, &block)
      async(&block)
      wait_for_tasks(**opts, text: msg)
    end

    def wait_for_tasks(**opts)
      @start = Time.now.to_i

      printer.reset!
      queue.consume

      until queue.clear?
        queue.consume
        progress(**opts)
        sleep 1.0 / 24
      end
    end

    class << self
      def lazy_loadable
        @lazy_loadable ||= Dir.glob(LAZY_LOAD_ROOT).map do |path|
          [path.split('/')[-2].to_s.to_sym, path]
        end.to_h
      end

      def prerequisites
        @prerequisites ||= []
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

      private

      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

        ENV['PATH'].split(File::PATH_SEPARATOR).find do |path|
          exts.find do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            exe if File.executable?(exe) && !File.directory?(exe)
          end
        end
      end

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

      def inherited(fragment_class)
        fragment_name = fragment_class.name.split(/(?=[[:upper:]])/)
                                      .map(&:downcase).join('_')

        define_method fragment_name do |*args, &block|
          return fragment_class.new(*args, **@opts) if skip? fragment_name

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
