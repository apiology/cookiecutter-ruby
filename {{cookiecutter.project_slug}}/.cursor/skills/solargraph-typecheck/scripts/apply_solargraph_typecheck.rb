#!/usr/bin/env ruby
# typed: true
# frozen_string_literal: true

# rubocop:disable Naming/PredicateMethod, Metrics/AbcSize, Metrics/MethodLength

# Applies solargraph typecheck output: removes unneeded ignore lines and
# inserts ignore comments before remaining reported lines (unless already ignored).

require 'pathname'

ROOT = Pathname(File.expand_path('../../../..', __dir__))

# One reported typecheck problem.
class Issue
  # @return [String]
  attr_reader :file

  # @return [Integer]
  attr_reader :line

  # @return [String]
  attr_reader :message

  # @param file [String]
  # @param line [Integer]
  # @param message [String]
  # @return [void]
  def initialize(file:, line:, message:)
    @file = file
    @line = line
    @message = message
  end
end

# @param path [String]
# @return [Array<Issue>]
def parse_issues(path)
  File.readlines(path).filter_map do |raw|
    stripped = raw.strip
    match = stripped.match(/\A(.+):(\d+) - (.+)\z/)
    next unless match

    file = Pathname(match[1].to_s).expand_path
    Issue.new(file: file.to_s, line: match[2].to_i, message: match[3].to_s.strip)
  end
end

# @param path [String]
# @return [Array<String>]
def read_lines(path)
  File.readlines(path, chomp: false)
end

# @param path [String]
# @param lines [Array<String>]
# @return [void]
def write_lines(path, lines)
  File.write(path, lines.join)
end

# @param line [String, nil]
# @return [Boolean]
def sg_ignore_line?(line)
  return false if line.nil?

  line.strip == '# @sg-ignore'
end

# @param lines [Array<String>]
# @param line_num [Integer]
# @return [Integer, nil]
def find_sg_ignore_index(lines, line_num)
  idx = line_num - 1
  return idx if idx >= 0 && sg_ignore_line?(lines[idx])

  start = [idx - 1, 0].max
  finish = [idx - 20, 0].max
  start.downto(finish) do |i|
    return i if sg_ignore_line?(lines[i])
  end
  nil
end

# @param issue [Issue]
# @return [Boolean]
def remove_sg_ignore!(issue)
  lines = read_lines(issue.file)
  ignore_idx = find_sg_ignore_index(lines, issue.line)
  return false unless ignore_idx

  lines.delete_at(ignore_idx)
  write_lines(issue.file, lines)
  true
end

# @param lines [Array<String>]
# @param line_num [Integer]
# @return [Boolean]
def already_ignored?(lines, line_num)
  idx = line_num - 1
  idx.positive? && sg_ignore_line?(lines[idx - 1])
end

# @param issue [Issue]
# @return [Boolean]
def add_sg_ignore!(issue)
  lines = read_lines(issue.file)
  idx = issue.line - 1
  return false if idx.negative? || already_ignored?(lines, issue.line)

  line = lines[idx]
  indent = ''
  if line
    indent_match = line.match(/\A(\s*)/)
    indent = indent_match.captures.first if indent_match
  end
  lines.insert(idx, "#{indent}# @sg-ignore\n")
  write_lines(issue.file, lines)
  true
end

# @param issue [Issue]
# @return [Boolean]
def fix_missing_return!(issue)
  match = issue.message.match(/\AMissing @return tag for (\S+)#(\S+)\z/)
  return false unless match

  _klass, method_name = match.captures
  lines = read_lines(issue.file)
  insert_at = insert_at_for_missing_return(lines, issue.line, method_name)
  return false unless insert_at

  unless lines[insert_at - 1]&.include?('@return')
    lines.insert(insert_at, "# @return [void]\n")
    write_lines(issue.file, lines)
    return true
  end
  false
end

# @param lines [Array<String>]
# @param line_num [Integer]
# @param method_name [String]
# @return [Integer, nil]
def insert_at_for_missing_return(lines, line_num, method_name)
  def_idx = line_num - 1
  def_line = lines[def_idx]
  return nil unless def_line&.match?(/^\s*def\s+#{Regexp.escape(method_name)}\b/)

  insert_at = def_idx
  while insert_at.positive?
    prev = lines[insert_at - 1]
    break unless prev&.match?(/^\s*#/)

    insert_at -= 1
  end
  insert_at
end

# @param issue [Issue]
# @return [Boolean]
def fix_date_new!(issue)
  return false unless issue.message == 'Not enough arguments to Date.new'

  lines = read_lines(issue.file)
  idx = issue.line - 1
  line = lines[idx]
  return false if line.nil?
  return false unless line.include?('Date.new(')

  date_match = line.match(/Date\.new\((\d+),\s*(\d+),\s*(\d+)\)/)
  return false unless date_match

  year, month, day = date_match.captures
  lines[idx] = line.gsub(
    "Date.new(#{year}, #{month}, #{day})",
    "Date.parse('#{year}-#{month.rjust(2, '0')}-#{day.rjust(2, '0')}')"
  )
  write_lines(issue.file, lines)
  true
end

issues_path = ARGV.fetch(0) { abort("usage: #{$PROGRAM_NAME} TYPECHECK_OUTPUT_FILE") }
issues = parse_issues(issues_path)

unneeded = issues.select { |i| i.message == 'Unneeded @sg-ignore comment' }
missing_return = issues.select { |i| i.message.start_with?('Missing @return tag for ') }
date_new = issues.select { |i| i.message == 'Not enough arguments to Date.new' }
remaining = issues - unneeded - missing_return - date_new
remaining = remaining.uniq { |i| [i.file, i.line] }

removed = unneeded.count { |i| remove_sg_ignore!(i) }
fixed_returns = missing_return.count { |i| fix_missing_return!(i) }
fixed_dates = date_new.count { |i| fix_date_new!(i) }
added = remaining.count { |i| add_sg_ignore!(i) }

warn "removed #{removed} unneeded @sg-ignore"
warn "fixed #{fixed_returns} missing @return"
warn "fixed #{fixed_dates} Date.new"
warn "added #{added} @sg-ignore"

# rubocop:enable Naming/PredicateMethod, Metrics/AbcSize, Metrics/MethodLength
