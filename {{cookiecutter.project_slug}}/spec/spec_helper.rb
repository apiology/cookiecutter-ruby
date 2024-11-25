# frozen_string_literal: true
{% if cookiecutter.use_checkoff == 'Yes' %}
# @sg-ignore
ENV['REDIS_HOSTNAME'] = 'deactivated-anyway'{% endif %}

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter,
  ]
)
SimpleCov.start do
  # @!parse
  #   extend SimpleCov::Configuration

  # this dir used by CircleCI
  add_filter 'vendor'
  track_files 'lib/**/*.rb'
  enable_coverage(:branch) # Report branch coverage to trigger branch-level undercover warnings
end

require 'webmock/rspec'

module LogCaptureHelper
  # @return [String]
  def capture_logs
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)

    yield

    log_output.string
  ensure
    Rails.logger = original_logger
  end
end

RSpec.configure do |config|
  config.include LogCaptureHelper

  config.around do |example|
    log_messages = capture_logs do
      example.run
    end

  ensure
    # ideally this would be stashed somewhere and retrieved in the
    # reporter so that these appear directly in the failure message
    # instead of out of ordre earlier
    if example.exception
      puts "\n--- Logs for #{example.inspect_output} ---\n"
      puts log_messages
    end
  end
end
RSpec.configure do |config|
  config.order = 'random'
end
