# frozen_string_literal: true

module CacheLab
  class ProductSource
    attr_reader :calls

    def initialize(delay_seconds:, sleeper: ->(seconds) { sleep(seconds) })
      @delay_seconds = delay_seconds
      @sleeper = sleeper
      @calls = 0
    end

    def fetch(id)
      @calls += 1
      @sleeper.call(@delay_seconds)

      { id: id }
    end
  end
end
