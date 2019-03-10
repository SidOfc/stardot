# frozen_string_literal: true

module Stardot
  class Printer
    LOAD_FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze

    COLORS = {
      info: :blue,
      ok: :green,
      error: :red,
      warn: 'D7875F',
      action: :default,
      gray: '#666'
    }.freeze

    def initialize
      @mutex = Mutex.new
      @frame = 0
    end

    def loader
      LOAD_FRAMES[@frame]
    end

    def tick!
      @frame += 1
      reset! if @frame >= LOAD_FRAMES.count - 1
    end

    def reset!
      @frame = 0
    end

    def echo(msg, **opts)
      msg = paint msg, opts[:color] if opts[:color]

      @mutex.synchronize do
        puts control_sequences(opts) + Printer.indent + msg
      end
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
      @indent << ' ' * (@last_amount = amount)
    end

    def self.unindent!(amount = @last_amount)
      @indent = indent[0..-(amount + 1)]
    end

    private

    def control_sequences(opts)
      seq = @soft ? "\r\e[A\e[K" : ''
      @soft = opts[:soft] ? true : false
      seq
    end
  end
end
