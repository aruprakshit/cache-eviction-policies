# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/cache_lab/product_source"

class ProductSourceTest < Minitest::Test
  def test_repeated_requests_each_reach_the_source
    source = CacheLab::ProductSource.new(delay_seconds: 0)

    products = %w[A A B A B].map do |id|
      source.fetch(id)
    end

    assert_equal(%w[A A B A B], products.map { |product| product.fetch(:id) })
    assert_equal 5, source.calls
  end

  def test_each_lookup_requests_the_configured_delay
    requested_delays = []

    sleeper = ->(seconds) { requested_delays << seconds }

    source = CacheLab::ProductSource.new(
      delay_seconds: 0.1,
      sleeper: sleeper
    )

    %w[A A B].each { |id| source.fetch(id) }

    assert_equal [0.1, 0.1, 0.1], requested_delays
  end
end
