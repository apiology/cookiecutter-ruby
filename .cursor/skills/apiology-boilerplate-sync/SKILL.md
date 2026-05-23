---
name: apiology-boilerplate-sync
description: >-
  Sync boilerplate for this cookiecutter template (cookiecutter-ruby,
  Ruby) from reference repos using only origin/main;
  respect hierarchical tiers (meta, language, project). Use when updating cookiecutter
  templates or comparing reference-repo drift.
disable-model-invocation: false
---

# Apiology boilerplate sync

**This template:** `cookiecutter-ruby` — Ruby cookiecutter.

## Hard rule

1. `git fetch origin main` in every repo involved.
2. Read with `git show origin/main:<path>` — never treat the working tree as shipped truth.
3. Record SHAs: `git log -1 --oneline origin/main`.

Read [docs/SYNCING_BOILERPLATE.md](../../docs/SYNCING_BOILERPLATE.md) and [template-hierarchy.mdc](../../.cursor/rules/template-hierarchy.mdc) in the repo you are editing.

## Cookiecutter family (hierarchical)

Templates stack **general → specific** (meta → language/tool → project). At **this** checkout:

- Port from reference repos only what fits **this** tier (Ruby).
- Do not push language/framework specifics to **ancestor** templates.
- Do not park **descendant-only** config here (narrower child cookiecutters own it).

Each language/tool cookiecutter repo typically carries:

- `.cursor/rules/boilerplate-sync.mdc`, `template-hierarchy.mdc`, `overcommit-signing.mdc` (at meta, language, and nested project tiers as applicable)
- `.cursor/skills/apiology-boilerplate-sync/`
- `docs/SYNCING_BOILERPLATE.md`

| Tier | Typical repo | Scope |
|------|--------------|--------|
| Meta | `cookiecutter-cookiecutter` | Bakes child templates; sync docs live under baked `cookiecutter-ruby/` |
| Language/tool | `cookiecutter-ruby` | Ruby boilerplate |
| Project | Nested `{{cookiecutter.project_slug}}/` inside a language template | End-user project layout — no sync skill |

**Path check:** when porting `.envrc`, Makefile paths, or hook `include`s — if the referenced directory or file **does not exist** in the template you are editing, it likely belongs in a **descendant** cookiecutter, not the current repo.

## Nested template directory (if present)

Some templates include a nested `{{cookiecutter.project_slug}}/` cookiecutter inside this repo. When editing **this** repo’s own files, propagate shared boilerplate to that nested path only when both are still the appropriate tier — otherwise treat nested paths per [template-hierarchy.mdc](../../.cursor/rules/template-hierarchy.mdc).

## Jinja / CircleCI

- Cookiecutter vars: `cookiecutter-ruby`, `Ruby`
- Circle `{{ checksum }}` in YAML: wrap in `...` in template sources

## Reference repos

Choose reference implementation(s) per task; record `origin/main` SHAs.

## Baseline paths (adjust per tier)

- `.circleci/config.yml`, `.envrc`, `.yamllint.yml`, `.gitattributes`, `.dockerignore`
- `.git-hooks/pre_commit/circle_ci.rb`, `.git-hooks/pre_commit/punchlist.rb` (maintenance)
- `.cursor/rules/`, `.cursor/skills/`, `docs/SYNCING_BOILERPLATE.md`
- `DEVELOPMENT.md` (sync / agent sections)

Before porting: `git ls-tree origin/main -- <path>`.

## Meta tier: Ruby reference exclusions

If the reference is a **Ruby app or gem** (e.g. `checkoff` or a private baked gem) and you are at the **meta** cookiecutter, do **not** port Ruby-only bootstrap or Sorbet artifacts into shared files:

- `fix.sh`: rbenv `--list-all`, `set_ruby_local_version` churn, `ensure_rugged_packages_installed` (**Ruby repos only** — not generic language templates), extra `ensure_rbenv`; project-only `handlebars` / `mini_racer` / `chromedriver` helpers
- `.gitignore`: `tapioca.installed`, `yardoc.installed`, `sorbet/machine_specific_config`
- `.git-hooks/**/*.rb`: `# @sg-ignore` and Sorbet-only annotations
- `.overcommit.yml` / `.yamllint.yml`: RuboCop, Sorbet, Solargraph, Brakeman, Fasterer, BundleAudit, Rake prepush, `sorbet/**` or `rbs_collection.lock.yaml` ignores
- `.circleci/config.yml`: `checkout: method: full`, debug `pwd`, app-specific cache checksums

**Rugged** (`ensure_rugged_packages_installed`) is **Ruby-repo-specific** — add it in `cookiecutter-gem` (or the baked app), not in this meta repo’s generic language template. Details: [template-hierarchy.mdc](../../.cursor/rules/template-hierarchy.mdc), [SYNCING_BOILERPLATE.md](../../docs/SYNCING_BOILERPLATE.md).

## Baked app references (private repos)

Before copying from a **production** or **private baked** repo into a cookiecutter template:

1. Identify which cookiecutter tier you are editing (meta / language / nested project).
2. Run a path-by-path diff; reject anything under `lib/`, app `config/`, or project-only `Makefile` / `Gemfile` unless this tier is meant to generate that layout.
3. **Good ports:** `env.local` + `.envrc`, 1Password docs, `.dockerignore`, `no_output_timeout`, `config/env.local` gitignore.
4. **Bad ports:** full reference `.overcommit.yml`, reference `.yamllint.yml` Ruby/Sorbet blocks, CircleCI debugging checkout, project native deps in `fix.sh` (see SYNCING doc).
5. **Naming:** do not put private reference repo names in public commits, PRs, or docs.

## Quick baseline

From the repo root (this cookiecutter checkout):

```bash
.cursor/skills/apiology-boilerplate-sync/scripts/baseline-main.sh \
  /path/to/cookiecutter-template /path/to/reference-repo
```

After syncing boilerplate here, propagate `.cursor/skills/apiology-boilerplate-sync/` (and related rules/docs) to sibling cookiecutter repos via `make update_from_cookiecutter` or your usual template merge workflow.

## After edits

- Confirm changes match this template’s tier (not ancestor-only or descendant-only).
- Run this repo’s tests (`pytest`, `make`, etc. as documented in `DEVELOPMENT.md`).

## Commits in this repo

If `git commit` fails with overcommit plugin signature / security messages, run `bin/overcommit --sign`, then `bin/overcommit --sign pre-commit`, then retry. See [overcommit-signing.mdc](../../rules/overcommit-signing.mdc).
