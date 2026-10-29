# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/cache_lab/product_source"
require_relative "../lib/cache_lab/experiment"

class ExperimentTest < Minitest::Test
  def test_uncached_baseline_reports_source_calls_for_the_request_sequence
    source = CacheLab::ProductSource.new(delay_seconds: 0)
    experiment = CacheLab::Experiment.new(source: source)

    result = experiment.run(%w[A A B A B])

    assert_equal 5, result.fetch(:requests)
    assert_equal 5, result.fetch(:source_calls)
    assert_equal(%w[A A B A B], result.fetch(:products).map { |product| product.fetch(:id) })
  end

  def test_source_call_count_is_isolated_to_each_run
    source = CacheLab::ProductSource.new(delay_seconds: 0)
    experiment = CacheLab::Experiment.new(source: source)

    source.fetch("existing")

    first_result = experiment.run(%w[A A B])
    second_result = experiment.run(%w[B A])

    assert_equal 3, first_result.fetch(:source_calls)
    assert_equal 2, second_result.fetch(:source_calls)
    assert_equal 6, source.calls
  end

  def test_reports_elapsed_seconds_using_the_supplied_clock
    source = CacheLab::ProductSource.new(delay_seconds: 0)
    timestamps = [10.0, 10.5]
    clock = -> { timestamps.shift }
    experiment = CacheLab::Experiment.new(source: source, clock: clock)

    result = experiment.run(%w[A A B A B])

    assert_in_delta 0.5, result.fetch(:elapsed_seconds), 0.000001
    assert_empty timestamps
  end
end
