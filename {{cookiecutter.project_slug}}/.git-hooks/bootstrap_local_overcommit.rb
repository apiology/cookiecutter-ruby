# typed: true
# frozen_string_literal: true

# Link machine-local Overcommit config into Cursor worktrees and defer signature
# verification until `overcommit --sign` has run in this worktree (via fix.sh).
require 'yaml'
require 'fileutils'

# @param path [String]
# @return [Hash, nil]
def load_local_overcommit_config(path)
  data = YAML.load_file(path)
  data.is_a?(Hash) ? data : nil
rescue StandardError
  nil
end

repo_root = String(`git rev-parse --show-toplevel 2>/dev/null`).strip
exit if repo_root.empty?

local_file = File.join(repo_root, '.local-overcommit.yml')
worktrees_prefix = File.expand_path('~/.cursor/worktrees')

if !File.exist?(local_file) && repo_root.start_with?("#{worktrees_prefix}/")
  rel = repo_root.delete_prefix("#{worktrees_prefix}/")
  repo_name = rel.split('/').first
  source = File.join(File.expand_path('~/src'), repo_name, '.local-overcommit.yml')
  # @sg-ignore FileUtils.ln_sf src path typing in bootstrap hook
  FileUtils.ln_sf(source, local_file) if File.exist?(source)
end

return unless File.exist?(local_file)

raw_config = load_local_overcommit_config(local_file)
return unless raw_config&.[]('verify_signatures') == false

signed = String(`git config --local --get overcommit.configuration.verifysignatures 2>/dev/null`).strip
# @sg-ignore ENV[]= not resolved on ENV class in Solargraph
ENV['OVERCOMMIT_NO_VERIFY'] = '1' if signed != '0'
