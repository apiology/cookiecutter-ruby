# frozen_string_literal: true

# Solargraph annotations for ActiveRecord callbacks (Rails apps and gems using AR).
#
# @!parse
#   module ActiveRecord::Callbacks
#     module ClassMethods
#       # @param args [Symbol, Array<Symbol>]
#       # @return [void]
#       def before_destroy(*args, &block); end
#     end
#   end
