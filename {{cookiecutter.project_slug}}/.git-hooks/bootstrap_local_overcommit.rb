# typed: true
# frozen_string_literal: true

# Link machine-local Overcommit config across git worktrees and defer signature
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

# @param repo_root [String]
# @return [String, nil]
def sibling_worktree_local_overcommit(repo_root)
  String(`git worktree list --porcelain 2>/dev/null`).each_line do |line|
    next unless line.start_with?('worktree ')

    worktree = line.delete_prefix('worktree ').strip
    next if worktree == repo_root

    candidate = File.join(worktree, '.local-overcommit.yml')
    return candidate if File.exist?(candidate)
  end
  nil
end

repo_root = String(`git rev-parse --show-toplevel 2>/dev/null`).strip
exit if repo_root.empty?

local_file = File.join(repo_root, '.local-overcommit.yml')

unless File.exist?(local_file)
  source = sibling_worktree_local_overcommit(repo_root)
  # @sg-ignore FileUtils.ln_sf src path typing in bootstrap hook
  FileUtils.ln_sf(source, local_file) if source
end

return unless File.exist?(local_file)

raw_config = load_local_overcommit_config(local_file)
return unless raw_config&.[]('verify_signatures') == false

signed = String(`git config --local --get overcommit.configuration.verifysignatures 2>/dev/null`).strip
# @sg-ignore Unresolved call to []= on RBS::Unnamed::ENVClass
ENV['OVERCOMMIT_NO_VERIFY'] = '1' if signed != '0'
