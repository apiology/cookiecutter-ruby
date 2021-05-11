# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  # this dir used by CircleCI
  add_filter 'vendor'
  enable_coverage(:branch) # Report branch coverage to trigger branch-level undercover warnings
end
SimpleCov.refuse_coverage_drop

RSpec.configure do |config|
  config.order = 'random'
end
