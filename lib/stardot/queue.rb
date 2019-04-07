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
      return tasks << -> { block.call } if workers < 2

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

      while tasks.any? && running.size < workers
        next unless (result = tasks.shift.call).is_a? Thread

        @running << result
        Stardot.watch result
      end
    end
  end
end
