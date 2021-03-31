# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  # this dir used by CircleCI
  add_filter 'vendor'
end
SimpleCov.refuse_coverage_drop

RSpec.configure do |config|
  config.order = 'random'
end
