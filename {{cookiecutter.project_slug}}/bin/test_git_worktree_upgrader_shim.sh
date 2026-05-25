#!/bin/bash
# Regression test: linked-worktree .git pointer prepare/restore for cookiecutter paths.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHIM="${ROOT}/bin/cookiecutter_project_upgrader_with_worktree_shim.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

cd "${TMP}"
git init -q
echo x > README.md
git add README.md
git commit -qm init
git branch feat
git worktree add wt feat -q

WT="${TMP}/wt"
POINTER="${WT}/.git"

if [ ! -f "${POINTER}" ] || ! grep -q '^gitdir: ' "${POINTER}"; then
  echo "fail: expected gitdir pointer at ${POINTER}" >&2
  exit 1
fi

GIT_DIR="$(git -C "${WT}" rev-parse --git-dir)"
BACKUP="${WT}/.make/git-worktree-pointer-test"

mkdir -p "${WT}/.make"
cp "${POINTER}" "${BACKUP}"
rm -f "${POINTER}"
ln -s "${GIT_DIR}" "${POINTER}"

COOKIECUTTER_DIR="${WT}/.git/cookiecutter/nested"
if ! mkdir -p "${COOKIECUTTER_DIR}"; then
  echo "fail: could not mkdir under symlinked .git" >&2
  exit 1
fi

rm -f "${POINTER}"
mv "${BACKUP}" "${POINTER}"

if ! grep -q '^gitdir: ' "${POINTER}"; then
  echo "fail: .git pointer not restored" >&2
  exit 1
fi

if [ -d "${COOKIECUTTER_DIR}" ]; then
  echo "fail: temp cookiecutter dir should not survive restore" >&2
  exit 1
fi

if [ ! -x "${SHIM}" ]; then
  echo "fail: shim not executable: ${SHIM}" >&2
  exit 1
fi

echo "ok: git worktree upgrader shim paths"
