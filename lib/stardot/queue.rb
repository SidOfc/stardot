# frozen_string_literal: true

module Stardot
  class Queue
    attr_accessor :tasks
    attr_reader   :running, :finished, :workers

    def initialize(tasks = [], workers: nil)
      @tasks    = tasks
      @running  = []
      @finished = []
      @workers  = workers || Stardot.cores
    end

    def add(&block)
      tasks << -> { Thread.new(&block) }
    end

    def total
      finished.size + running.size + tasks.size
    end

    def completed
      finished.size
    end

    def clear?
      (total - completed).zero?
    end

    def consume
      finished   = running.reject(&:status)
      @finished += finished
      @running  -= finished

      Stardot.unwatch(*finished)
      finished.each(&:join)
      replenish
    end

    private

    def replenish
      while tasks.any? && running.size < workers
        thread = tasks.shift.call

        next thread.join unless Stardot.concurrent?

        @running << thread
        Stardot.watch thread
      end
    end
  end
end
