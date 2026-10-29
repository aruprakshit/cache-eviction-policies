# frozen_string_literal: true

require_relative "../lib/cache_lab/product_source"
require_relative "../lib/cache_lab/experiment"

ids = %w[A A B A B]
source = CacheLab::ProductSource.new(delay_seconds: 0.1)
experiment = CacheLab::Experiment.new(source: source)

result = experiment.run(ids)

puts "Policy: none (uncached)"
puts "Sequence: #{ids.join(', ')}"
puts "Requests: #{result.fetch(:requests)}"
puts "Source calls: #{result.fetch(:source_calls)}"
puts "Returned IDs: #{result.fetch(:products).map { |product| product.fetch(:id) }.join(', ')}"
puts format("Elapsed: %.3f seconds", result.fetch(:elapsed_seconds))
