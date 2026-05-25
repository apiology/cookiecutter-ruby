#!/bin/bash
# Run cookiecutter_project_upgrader and the update_from_cookiecutter finish phase.
# Handles linked git worktrees (gitdir: .git pointer) and worktree-safe git branch ops.

set -euo pipefail

bin/overcommit --uninstall
cookiecutter_project_upgrader --help >/dev/null

MAIN_REPO_ROOT="$(dirname "$(git rev-parse --git-common-dir)")"
GIT_DIR_PATH="$(git rev-parse --git-dir)"
MAKE_DIR=".make"
RBS_HIDDEN=0
RUBOCOP_MAIN_HIDDEN=0
RUBOCOP_CWD_HIDDEN=0
GIT_WORKTREE_SHIM=0
REPO_CWD="$(pwd)"

cleanup_prepare() {
  if [ "${GIT_WORKTREE_SHIM}" -eq 1 ] && [ -f "${MAKE_DIR}/git-worktree-pointer" ]; then
    rm -f .git
    mv "${MAKE_DIR}/git-worktree-pointer" .git
    GIT_WORKTREE_SHIM=0
  fi
  if [ "${RBS_HIDDEN}" -eq 1 ] && [ -f "${MAKE_DIR}/rbs_collection.yaml.bak" ]; then
    mv "${MAKE_DIR}/rbs_collection.yaml.bak" "${MAIN_REPO_ROOT}/rbs_collection.yaml"
    rm -f "${MAKE_DIR}/rbs_collection_yaml_hidden"
    RBS_HIDDEN=0
  fi
  if [ "${RUBOCOP_MAIN_HIDDEN}" -eq 1 ] && [ -f "${MAKE_DIR}/rubocop-main.yml.bak" ]; then
    mv "${MAKE_DIR}/rubocop-main.yml.bak" "${MAIN_REPO_ROOT}/.rubocop.yml"
    rm -f "${MAKE_DIR}/rubocop_main_hidden"
    RUBOCOP_MAIN_HIDDEN=0
  fi
  if [ "${RUBOCOP_CWD_HIDDEN}" -eq 1 ] && [ -f "${MAKE_DIR}/rubocop-cwd.yml.bak" ]; then
    mv "${MAKE_DIR}/rubocop-cwd.yml.bak" "${REPO_CWD}/.rubocop.yml"
    rm -f "${MAKE_DIR}/rubocop_cwd_hidden"
    RUBOCOP_CWD_HIDDEN=0
  fi
  if [ -d "${GIT_DIR_PATH}/cookiecutter" ]; then
    rm -rf "${GIT_DIR_PATH}/cookiecutter"
  fi
}

trap cleanup_prepare EXIT

mkdir -p "${MAKE_DIR}"

if [ -f docs/cookiecutter_input.json ]; then
  jq 'del(._output_dir, ._repo_dir, ._checkout)' docs/cookiecutter_input.json \
    > "${MAKE_DIR}/cookiecutter_context.json"
fi

if [ -f "${MAIN_REPO_ROOT}/rbs_collection.yaml" ]; then
  mv "${MAIN_REPO_ROOT}/rbs_collection.yaml" "${MAKE_DIR}/rbs_collection.yaml.bak"
  touch "${MAKE_DIR}/rbs_collection_yaml_hidden"
  RBS_HIDDEN=1
fi
if [ -f "${MAIN_REPO_ROOT}/.rubocop.yml" ]; then
  mv "${MAIN_REPO_ROOT}/.rubocop.yml" "${MAKE_DIR}/rubocop-main.yml.bak"
  touch "${MAKE_DIR}/rubocop_main_hidden"
  RUBOCOP_MAIN_HIDDEN=1
fi
# Nested tiers may have their own .rubocop.yml; hide it so RuboCop does not inherit
# mismatched config while cookiecutter_project_upgrader runs under .git/cookiecutter/
if [ -f "${REPO_CWD}/.rubocop.yml" ]; then
  mv "${REPO_CWD}/.rubocop.yml" "${MAKE_DIR}/rubocop-cwd.yml.bak"
  touch "${MAKE_DIR}/rubocop_cwd_hidden"
  RUBOCOP_CWD_HIDDEN=1
fi

if [ -f .make/git-worktree-pointer ] && [ ! -f .git ] && [ ! -L .git ]; then
  echo "error: stale ${MAKE_DIR}/git-worktree-pointer but .git is missing; restore manually" >&2
  exit 1
fi

if [ -f .git ] && [ ! -L .git ] && grep -q '^gitdir: ' .git; then
  cp .git "${MAKE_DIR}/git-worktree-pointer"
  rm -f .git
  ln -s "${GIT_DIR_PATH}" .git
  GIT_WORKTREE_SHIM=1
elif [ -f .git ] && [ ! -L .git ]; then
  echo "error: .git is a regular file but not a linked-worktree gitdir pointer" >&2
  exit 1
fi

export IN_COOKIECUTTER_PROJECT_UPGRADER=1
if [ -f "${MAKE_DIR}/cookiecutter_context.json" ]; then
  cookiecutter_project_upgrader -c "${MAKE_DIR}/cookiecutter_context.json" -p true
else
  cookiecutter_project_upgrader
fi

trap - EXIT
cleanup_prepare

# Finish phase (worktree-safe: no checkout of branches locked in other worktrees)
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
if git symbolic-ref -q "refs/remotes/origin/HEAD" >/dev/null 2>&1; then
  DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
fi

if ! git diff --quiet -- Makefile 2>/dev/null || ! git diff --cached --quiet -- Makefile 2>/dev/null; then
  git stash push -m 'update_from_cookiecutter Makefile' -- Makefile
  touch "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

git push --no-verify origin cookiecutter-template || true

git fetch "origin" "${DEFAULT_BRANCH}"
UPDATE_BRANCH="update-from-cookiecutter-$(date +%Y-%m-%d-%H%M)"
git switch -c "${UPDATE_BRANCH}" "origin/${DEFAULT_BRANCH}"
echo "Created branch ${UPDATE_BRANCH} from origin/${DEFAULT_BRANCH}"

bin/overcommit --sign
bin/overcommit --sign pre-commit
bin/overcommit --sign pre-push

git merge cookiecutter-template || true
git checkout --ours Gemfile.lock || true

if [ -f "${MAKE_DIR}/cookiecutter_makefile_stashed" ]; then
  git stash pop || true
  rm -f "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

bundle update --conservative json rexml || true
( make build && git add Gemfile.lock ) || true
bin/overcommit --install || true

echo
echo "Please resolve any merge conflicts below and push up a PR with:"
echo
echo '   gh pr create --title "Update from cookiecutter" --body "Automated PR to update from cookiecutter boilerplate"'
echo
