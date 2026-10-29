# frozen_string_literal: true

module CacheLab
  class Experiment
    def initialize(source:, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      @source = source
      @clock = clock
    end

    def run(ids)
      calls_before = @source.calls
      started_at = @clock.call
      products = ids.map { |id| @source.fetch(id) }
      elapsed_seconds = @clock.call - started_at

      {
        requests: products.length,
        source_calls: @source.calls - calls_before,
        products: products,
        elapsed_seconds: elapsed_seconds
      }
    end
  end
end
