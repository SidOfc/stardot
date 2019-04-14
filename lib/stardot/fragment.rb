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

      until self.class.prerequisites.empty?
        instance_eval(&self.class.prerequisites.shift)
      end

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
      parts = progress_parts.map { |str, clr| printer.paint str, color: clr }
      printer.echo parts.join(' '),
                   soft: queue.clear? ? !opts.fetch(:sticky, false) : true
    end

    def progress_parts
      c1, c2 = queue.clear? ? %i[ok default] : %i[warn gray]

      [[queue.clear? ? '★' : printer.loader, c1],
       [progress_time_passed,                c2],
       ["#{queue.completed}/#{queue.total}", c1],
       ['finished',                          c1]]
    end

    def progress_time_passed
      "[#{format('%02d:%02d:%02d',
                 *time_passed(@start).instance_eval { [hour, min, sec] })}]"
    end

    def skip?(fragment_name)
      action_name = fragment_name.split(/(?=[[:upper:]_\-.])/)
                                 .map(&:downcase).join '_'

      if ARGV.any? { |arg| arg =~ /^--only-\w+/ }
        ARGV.none?(/^--only-#{action_name}/)
      else
        ARGV.any? { |arg| arg =~ /^--skip-#{action_name}/ }
      end
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

      def inherited(frag_class)
        frag_name = frag_class.name.split(/(?=[[:upper:]])/)
                              .map(&:downcase).join '_'

        define_method frag_name do |*args, &block|
          return frag_class.new(*args, **@opts) if skip? frag_name

          printer.echo "★ #{frag_name}", color: :action, style: :bold
          printer.indented { frag_class.new(*args, **@opts, &block).process }
        end
      end
    end
  end
end
