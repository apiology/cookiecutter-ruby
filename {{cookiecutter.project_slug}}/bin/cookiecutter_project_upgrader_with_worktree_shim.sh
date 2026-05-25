#!/bin/bash
# Run cookiecutter_project_upgrader from the repo root, including linked git worktrees.
#
# cookiecutter_project_upgrader writes under $PWD/.git/cookiecutter/. In a linked
# worktree, .git is a gitdir: pointer file, not a directory — temporarily symlink .git
# to $(git rev-parse --git-dir) so os.path.join(..., ".git", "cookiecutter") works.
#
# RuboCop can inherit config from MAIN_REPO_ROOT when regenerating under .git/cookiecutter/;
# optionally hide rbs_collection.yaml and .rubocop.yml there during the run.

set -euo pipefail

MAIN_REPO_ROOT="$(dirname "$(git rev-parse --git-common-dir)")"
GIT_DIR_PATH="$(git rev-parse --git-dir)"
MAKE_DIR=".make"

RBS_HIDDEN=0
RUBOCOP_MAIN_HIDDEN=0
GIT_WORKTREE_SHIM=0

cleanup() {
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
  if [ -d "${GIT_DIR_PATH}/cookiecutter" ]; then
    rm -rf "${GIT_DIR_PATH}/cookiecutter"
  fi
}

trap cleanup EXIT

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
upgrader_status=0
if [ -f "${MAKE_DIR}/cookiecutter_context.json" ]; then
  cookiecutter_project_upgrader -c "${MAKE_DIR}/cookiecutter_context.json" -p true || upgrader_status=$?
else
  cookiecutter_project_upgrader || upgrader_status=$?
fi
trap - EXIT
cleanup
exit "${upgrader_status}"
