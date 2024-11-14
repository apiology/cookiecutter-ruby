# https://gist.github.com/castwide/28b349566a223dfb439a337aea29713e
#
# The following comments fill some of the gaps in Solargraph's
# understanding of types. Since they're all in YARD, they get mapped
# in Solargraph but ignored at runtime.
#
# You can put this file anywhere in the project, as long as it gets included in
# the workspace maps. It's recommended that you keep it in a standalone file
# instead of pasting it into an existing one.
#
# @!override Hash<[String,Symbol],String>#fetch
#   @return [String>]
#
# @!parse
#   class ENV
#     # @param key [String]
#     # @param default [Object]
#     #
#     # @return [Object,nil]
#     def self.fetch(key, default = :none); end
#     # @param key [String]
#     #
#     # @return [Object,nil]
#     def self.[](key); end
#   end
#   module Bundler
#     class << self
#       # @param groups [Array<Symbol>]
#       #
#       # @return [void]
#       def require(*groups); end
#     end
#   end
