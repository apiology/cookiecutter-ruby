# frozen_string_literal: true

# Solargraph annotations for SimpleCov configuration DSL in spec_helper.
#
# @!parse
#   module SimpleCov
#     class Configuration
#       # @param criterion [:line, :branch]
#       # @return [void]
#       def enable_coverage(criterion = :line); end
#     end
#   end
