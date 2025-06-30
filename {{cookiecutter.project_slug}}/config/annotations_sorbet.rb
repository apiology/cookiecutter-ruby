# frozen_string_literal: true

require 'sorbet-runtime'

# @!parse
#   module T
#     class Struct
#       extend T::Props::ClassMethods
#     end
#
#     # @param type [T::Types::Base,::Class<Object>]
#     # @return [T::Types::Base]
#     def nilable(type); end
#
#     # @generic T
#     # @param o [generic<T>]
#     # @param type [Class<generic<T>>]
#     # @return [generic<T>]
#     def let(o, type); end
#
#     # @return [T::Types::Base]
#     def self.untyped; end
#   end
