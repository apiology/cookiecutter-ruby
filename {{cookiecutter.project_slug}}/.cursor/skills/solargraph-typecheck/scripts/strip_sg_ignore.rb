#!/usr/bin/env ruby
# typed: true
# frozen_string_literal: true

# Removes standalone Solargraph ignore-comment lines from paths given as arguments.

require 'pathname'

ROOT = Pathname(File.expand_path('../../../..', __dir__))

# @param arg [String]
# @return [Array<Pathname>]
def paths_for_arg(arg)
  path = Pathname(arg)
  path = ROOT.join(arg) unless path.absolute?
  if path.directory?
    path.glob('**/*.rb')
  else
    [path]
  end
end

paths = ARGV.flat_map { |arg| paths_for_arg(arg) }

changed = 0
paths.each do |file|
  next unless file.file?

  lines = File.readlines(file, chomp: false)
  filtered = lines.reject { |line| line.strip == '# @sg-ignore' }
  next if filtered.size == lines.size

  File.write(file, filtered.join)
  changed += 1
  warn "stripped #{file.relative_path_from(ROOT)}"
end

warn "updated #{changed} files"
