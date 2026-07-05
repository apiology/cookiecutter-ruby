# frozen_string_literal: true

# Solargraph annotations for SimpleCov configuration DSL in spec_helper.
#
# @!parse
#   module SimpleCov
#     module Configuration
#       # @overload enable_coverage(:line)
#       # @overload enable_coverage(:branch)
#       # @return [void]
#       def enable_coverage(criterion = :line); end
#     end
#   end
