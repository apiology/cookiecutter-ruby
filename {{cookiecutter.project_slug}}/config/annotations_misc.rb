# frozen_string_literal: true
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
# Do not add a YARD `class ENV` stub here. What Solargraph does under strong:
#
# 1. Stdlib RBS defines `ENV` as the singleton-like `RBS::Unnamed::ENVClass`
#    with instance methods `[]`, `[]=`, `fetch`, etc.
# 2. Separately, Solargraph still keeps a Ruby-core / constant pin that treats
#    `ENV` as related to `::ENV` / `Class<ENV>` (the top-level ENV object's
#    class-ish view of the same constant).
# 3. At call sites, those pins are **unioned**. Strong then probes methods on
#    `RBS::Unnamed::ENVClass, Class<ENV>`. Lookup requires the method to exist
#    on *every* member of a union; `[]` / `[]=` / `fetch` exist on `ENVClass`
#    but not on `Class<ENV>`, so the call is reported unresolved even though
#    the RBS half is correct.
# 4. Adding a YARD `class ENV` stub adds yet another pin and makes the union
#    wider / worse — it does not replace the RBS type.
#
# Keep normal `ENV[...]` / `ENV[]=` / `ENV.fetch` call sites and use a one-line
# Solargraph ignore (`sg-ignore`) with the strong error text when the union
# fails. Do not use `ENV.send` — that only swaps conventional rejected ENV
# access for unconventional code that Solargraph happens to ignore; it does not
# typecheck any better.
#
# @!override FileUtils.ln_sf
#   @param src [String]
#   @param dest [String]
#   @param options [Hash]
#   @return [void]
#
# @!override YAML.load_file
#   @param path [String]
#   @return [Object, nil]
#
# @!parse
#   module Psych
#     class << self
#       # @param path [String]
#       # @return [Object, nil]
#       def load_file(path); end
#     end
#   end
#   module YAML
#     class << self
#       # @param path [String]
#       # @return [Object, nil]
#       def load_file(path); end
#     end
#   end
#   module FileUtils
#     class << self
#       # Accept String paths — stdlib RBS FileUtils::path is overly narrow under
#       # Solargraph strong for plain String call sites.
#       # @param src [String]
#       # @param dest [String]
#       # @param options [Hash]
#       # @return [void]
#       def ln_sf(src, dest, **options); end
#     end
#   end
#   class StringIO
#     # @return [String]
#     def string; end
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
#     # https://ruby-doc.org/3.2.2/exts/date/Time.html#method-i-to-date#
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
