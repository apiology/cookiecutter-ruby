# frozen_string_literal: true

require 'sorbet-runtime'

# @!parse
#   module T
#     class Struct
#       extend T::Props::ClassMethods
#     end
#     # @param type [T::Types::Base,Class<Object>]
#     # @return [T::Types::Base]
#     def self.nilable(type)
#     end
#     # @return [T::Types::Base]
#     def self.untyped
#     end
#   end
