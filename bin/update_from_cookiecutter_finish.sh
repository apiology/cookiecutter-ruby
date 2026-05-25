#!/bin/bash
# Finish phase for make update_from_cookiecutter — safe from linked git worktrees.
#
# Does not checkout main or cookiecutter-template (those branches may be checked
# out in another worktree). Uses ref-based push, fetch, switch -c, and merge.

set -euo pipefail

MAKE_DIR=".make"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

if git symbolic-ref -q "refs/remotes/origin/HEAD" >/dev/null 2>&1; then
  DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
fi

mkdir -p "${MAKE_DIR}"

if ! git diff --quiet -- Makefile 2>/dev/null || ! git diff --cached --quiet -- Makefile 2>/dev/null; then
  git stash push -m 'update_from_cookiecutter Makefile' -- Makefile
  touch "${MAKE_DIR}/cookiecutter_makefile_stashed"
fi

# Upgrader with -p true already pushed; re-push without checking out the branch.
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
