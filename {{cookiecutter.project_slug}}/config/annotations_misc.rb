# typed: strict

#
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
#     # @return [String,:none,nil]
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
#   module OpenSSL
#     module SSL
#       # @type [Integer]
#       VERIFY_PEER = 1
#       # @type [Integer]
#       VERIFY_NONE = 0
#     end
#   end
#   class Time
#     class << self
#       # @param time [String]
#       # @param now [nil,Time]
#       # @return [Time]
#       def parse(time, now=nil); end
#     end
#     # https://ruby-doc.org/3.2.2/exts/date/Time.html#method-i-to_date#
#     # @return [Date]
#     def to_date; end
#   end
#   class Date
#     class << self
#       # @param date [String]
#       # @param comp [Boolean]
#       # @param state [Object]
#       # @return [Date]
#       def parse(date='-4712-01-01', comp=true, state=Date::ITALY); end
#       # @param start [Integer]
#       # @return [Date]
#       def today(start=Date::ITALY); end
#     end
#   end
