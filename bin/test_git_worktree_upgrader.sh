#!/bin/bash
# Regression test: linked-worktree .git pointer prepare/restore for cookiecutter paths.

set -euo pipefail

run_worktree_path_test() {
  local upgrader="$1"
  local label="$2"

  (
  set -euo pipefail
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT

  cd "${tmp}"
  git init -q
  echo x > README.md
  git add README.md
  git commit -qm init
  git branch feat
  git worktree add wt feat -q

  local wt="${tmp}/wt"
  local pointer="${wt}/.git"

  if [ ! -f "${pointer}" ] || ! grep -q '^gitdir: ' "${pointer}"; then
    echo "fail (${label}): expected gitdir pointer at ${pointer}" >&2
    return 1
  fi

  local git_dir
  git_dir="$(git -C "${wt}" rev-parse --git-dir)"
  local backup="${wt}/.make/git-worktree-pointer-test"

  mkdir -p "${wt}/.make"
  cp "${pointer}" "${backup}"
  rm -f "${pointer}"
  ln -s "${git_dir}" "${pointer}"

  local cookiecutter_dir="${wt}/.git/cookiecutter/nested"
  if ! mkdir -p "${cookiecutter_dir}"; then
    echo "fail (${label}): could not mkdir under symlinked .git" >&2
    return 1
  fi

  rm -f "${pointer}"
  mv "${backup}" "${pointer}"

  if ! grep -q '^gitdir: ' "${pointer}"; then
    echo "fail (${label}): .git pointer not restored" >&2
    return 1
  fi

  if [ -d "${cookiecutter_dir}" ]; then
    echo "fail (${label}): temp cookiecutter dir should not survive restore" >&2
    return 1
  fi

  if [ ! -x "${upgrader}" ]; then
    echo "fail (${label}): upgrader script not executable: ${upgrader}" >&2
    return 1
  fi

  echo "ok: git worktree upgrader paths (${label})"
  )
}

test_tier() {
  local tier_root="$1"
  local label="$2"
  run_worktree_path_test "${tier_root}/bin/cookiecutter_project_upgrader.sh" "${label}"
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
meta_root="$(cd "${script_dir}/.." && pwd)"
nested_slug='cookiecutter-ruby'
deep_nested="${meta_root}/${nested_slug}/{{cookiecutter.project_slug}}"

if [ "${1:-}" = "--all-tiers" ]; then
  test_tier "${meta_root}" "meta root"
  test_tier "${meta_root}/${nested_slug}" "nested tier"
  test_tier "${deep_nested}" "deep nested tier"
else
  test_tier "${meta_root}" "$(basename "${meta_root}")"
fi
