#!/bin/bash
# Run cookiecutter_project_upgrader and the update_from_cookiecutter finish phase.
# Handles linked git worktrees (gitdir: .git pointer) and worktree-safe git branch ops.
# Ecosystem-specific post-sync steps belong in Makefile post_cookiecutter_sync.

set -euo pipefail

bin/overcommit --uninstall
cookiecutter_project_upgrader --help >/dev/null

MAIN_REPO_ROOT="$(dirname "$(git rev-parse --git-common-dir)")"
GIT_DIR_PATH="$(git rev-parse --git-dir)"
MAKE_DIR=".make"
TEMPLATE_BRANCH="${COOKIECUTTER_TEMPLATE_BRANCH:-cookiecutter-template}"
TEMPLATE_UPGRADE_BRANCH="${COOKIECUTTER_TEMPLATE_UPGRADE_BRANCH:-main}"
GIT_WORKTREE_SHIM=0
REPO_CWD="$(pwd)"
HIDDEN_BACKUPS=()
HIDDEN_BACKUP_COUNT=0

hide_for_bake() {
  local src=$1 bak=$2
  if [ -f "${src}" ]; then
    mv "${src}" "${bak}"
    HIDDEN_BACKUPS+=("${bak}|${src}")
    HIDDEN_BACKUP_COUNT=$((HIDDEN_BACKUP_COUNT + 1))
  fi
}

restore_hidden() {
  local entry bak dest
  if [ "${HIDDEN_BACKUP_COUNT}" -eq 0 ]; then
    return 0
  fi
  for entry in "${HIDDEN_BACKUPS[@]}"; do
    bak="${entry%%|*}"
    dest="${entry#*|}"
    [ -f "${bak}" ] && mv "${bak}" "${dest}"
  done
  HIDDEN_BACKUPS=()
  HIDDEN_BACKUP_COUNT=0
}

cleanup_prepare() {
  if [ "${GIT_WORKTREE_SHIM}" -eq 1 ] && [ -f "${MAKE_DIR}/git-worktree-pointer" ]; then
    rm -f .git
    mv "${MAKE_DIR}/git-worktree-pointer" .git
    GIT_WORKTREE_SHIM=0
  fi
  restore_hidden
  [ -d "${GIT_DIR_PATH}/cookiecutter" ] && rm -rf "${GIT_DIR_PATH}/cookiecutter"
}

trap cleanup_prepare EXIT

mkdir -p "${MAKE_DIR}"

CONTEXT_FILE="${MAKE_DIR}/cookiecutter_context.json"
TEMPLATE_URL=""
if [ -f docs/cookiecutter_input.json ]; then
  jq 'del(._output_dir, ._repo_dir, ._checkout)' docs/cookiecutter_input.json \
    > "${CONTEXT_FILE}"
  TEMPLATE_URL="$(jq -r '._template // empty' "${CONTEXT_FILE}")"
fi

cookiecutter_cache_dir() {
  local url=$1 name=""
  if [[ "${url}" =~ github\.com[:/][^/]+/([^/.]+) ]]; then
    name="${BASH_REMATCH[1]}"
  elif [[ "${url}" =~ ^git@github\.com:[^/]+/([^/.]+) ]]; then
    name="${BASH_REMATCH[1]}"
  else
    return 1
  fi
  printf '%s\n' "${HOME}/.cookiecutters/${name}"
}

wipe_template_cache() {
  local url=$1 cache=""
  cache="$(cookiecutter_cache_dir "${url}")" || return 0
  if [ -e "${cache}" ]; then
    echo "Removing cookiecutter cache ${cache}"
    rm -rf "${cache}"
  fi
}

hide_for_bake "${MAIN_REPO_ROOT}/rbs_collection.yaml" "${MAKE_DIR}/rbs_collection.yaml.bak"
hide_for_bake "${MAIN_REPO_ROOT}/.rubocop.yml" "${MAKE_DIR}/rubocop-main.yml.bak"
hide_for_bake "${REPO_CWD}/.rubocop.yml" "${MAKE_DIR}/rubocop-cwd.yml.bak"

if [ -f .make/git-worktree-pointer ] && [ ! -e .git ]; then
  echo "error: stale ${MAKE_DIR}/git-worktree-pointer but .git missing" >&2
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

[ -n "${TEMPLATE_URL}" ] && wipe_template_cache "${TEMPLATE_URL}"

export IN_COOKIECUTTER_PROJECT_UPGRADER=1
UPGRADER_ARGS=(-p true -u "${TEMPLATE_UPGRADE_BRANCH}")
[ -f "${CONTEXT_FILE}" ] && UPGRADER_ARGS=(-c "${CONTEXT_FILE}" "${UPGRADER_ARGS[@]}")
if ! cookiecutter_project_upgrader "${UPGRADER_ARGS[@]}"; then
  if ! git rev-parse --verify "${TEMPLATE_BRANCH}" &>/dev/null; then
    >&2 echo "error: upgrader failed and ${TEMPLATE_BRANCH} is missing"
    exit 1
  fi
  echo "cookiecutter_project_upgrader reported no template diff"
fi

trap - EXIT
cleanup_prepare

DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
if git symbolic-ref -q refs/remotes/origin/HEAD &>/dev/null; then
  DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
fi

if ! git diff --quiet -- Makefile 2>/dev/null \
  || ! git diff --cached --quiet -- Makefile 2>/dev/null; then
  git stash push -m 'update_from_cookiecutter Makefile' -- Makefile
  touch "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

git push --no-verify origin "${TEMPLATE_BRANCH}"
git fetch origin "${DEFAULT_BRANCH}"

UPDATE_BRANCH="update-from-cookiecutter-$(date +%Y-%m-%d-%H%M)"
git switch -c "${UPDATE_BRANCH}" "origin/${DEFAULT_BRANCH}"
echo "Created branch ${UPDATE_BRANCH} from origin/${DEFAULT_BRANCH}"

bin/overcommit --sign
bin/overcommit --sign pre-commit
bin/overcommit --sign pre-push

git merge "${TEMPLATE_BRANCH}"
git checkout --ours Gemfile.lock || true

if [ -f "${MAKE_DIR}/cookiecutter_makefile_stashed" ]; then
  git stash pop || true
  rm -f "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

bin/overcommit --install || true

cat <<'EOF'

Please resolve any merge conflicts below and push up a PR with:

   gh pr create --title "Update from upstream" --body "Automated PR to update from upstream boilerplate"

EOF
