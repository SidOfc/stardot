# frozen_string_literal: true

module Stardot
  class Printer
    LOAD_FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
    MUTEX = Mutex.new

    COLORS = {
      info:   :blue,
      ok:     :green,
      error:  :red,
      warn:   'D7875F',
      action: :default,
      gray:   '#666'
    }.freeze

    def initialize(**opts)
      @frame = 0
      @silent = opts[:silent] ? true : false
    end

    def loader
      sprite = LOAD_FRAMES[@frame]

      @frame += 1
      reset! if @frame >= LOAD_FRAMES.count - 1

      sprite
    end

    def done
      '★'
    end

    def reset!
      @frame = 0
    end

    def locked
      MUTEX.lock
      yield
      MUTEX.unlock
    end

    def echo(msg, **opts)
      return if @silent

      msg = paint msg, opts[:color] if opts[:color]

      MUTEX.synchronize do
        puts control_sequences(opts) + Printer.indent + msg + debug
      end
    end

    def debug
      return ""
      " (soft: #{Printer.soft ? 1 : 0})"
    end

    def paint(msg, color = :default)
      Paint[msg, COLORS.fetch(color, color)]
    end

    def indent
      Printer.indent!
    end

    def unindent
      Printer.unindent!
    end

    def self.indent
      @indent ||= +''
    end

    def self.indent!(amount = 2)
      indent << ' ' * (@last_amount = amount)
    end

    def self.unindent!(amount = @last_amount)
      @indent = indent[0..-(amount + 1)]
    end

    def self.soft
      @soft ||= false
    end

    def self.soft=(bool)
      @soft = bool
    end

    private

    def control_sequences(opts)
      seq = Printer.soft ? "\r\e[A\e[K" : ''
      Printer.soft = opts[:soft] ? true : false
      seq
    end
  end
end
