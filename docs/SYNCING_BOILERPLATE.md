# Syncing boilerplate from reference repos

**This template:** `cookiecutter-ruby` (Ruby cookiecutter).

This repo is one tier in a **hierarchical** cookiecutter family (general → specific). The same workflow applies whether you are at the meta, language, or framework layer — only the **scope** changes.

## Source of truth: `origin/main` only

Do **not** use local working trees as the source of truth.

```bash
git fetch origin main
git rev-parse --short origin/main
git show origin/main:<path>
```

Record SHAs in your PR when syncing.

## Hierarchy (read at every tier)

| Direction | Rule |
|-----------|------|
| Reference → **this** template | Port only what fits **this** level (Ruby). |
| Reference → **descendant** templates | Do not add here; use a more specific child cookiecutter. |
| **Ancestor** → this template | Pull agnostic fixes down; never push specificity **up**. |
| **This** → **descendants** | Push tier-appropriate config down; keep narrower bits in children. |

Details: `.cursor/rules/template-hierarchy.mdc`.

## Reference repos

At sync time, choose reference implementation(s) and record their `origin/main` SHAs. Paths on disk are whatever you use locally; they are not fixed in this doc.

## Paths often in scope (language-agnostic baseline)

Adjust for **this** tier — a reference repo may include more than you should port here.

- `.circleci/config.yml`
- `.envrc`, `.yamllint.yml`, `.gitattributes`, `.dockerignore`
- `.git-hooks/pre_commit/circle_ci.rb`, `.git-hooks/pre_commit/punchlist.rb` (maintenance only)
- `.cursor/rules/`, this doc
- `DEVELOPMENT.md` (agent/conventions sections)
- `CODE_OF_CONDUCT.md`, `.mdlrc`, `package.json` (usually unchanged)

Defer to **descendant** templates: app `lib/`, framework-only hooks, language stacks narrower than this repo’s scope.

### Meta tier: do not port from Ruby app references

When the reference is a **Ruby application or gem** (e.g. `apiology/checkoff`) and you are editing the **meta** cookiecutter (`cookiecutter-cookiecutter` root or its parallel nested copies of cross-language files), **do not** port:

- **`fix.sh`:** `rbenv install --list-all`, changes to `set_ruby_local_version` (`tail -1`, extra `set_rbenv_env_variables`), `ensure_rugged_packages_installed`, or a standalone `ensure_rbenv` call before the main install flow
- **`.gitignore`:** `tapioca.installed`, `yardoc.installed`, `sorbet/machine_specific_config`
- **`.git-hooks/**/*.rb`:** `# @sg-ignore` and other Sorbet-only typing churn from the reference

Those belong in a **Ruby language** cookiecutter (e.g. `cookiecutter-ruby`), not the meta template. See `.cursor/rules/template-hierarchy.mdc` (meta and language tiers).

### Baked Ruby apps (private reference repos)

A typical repo generated from `cookiecutter-gem` is a useful reference. When using any baked gem/app as a reference:

1. **Confirm tier** — meta vs language cookiecutter vs nested project template vs “never port.”
2. **Prefer agnostic wins** — `config/env.local`, `.envrc`, 1Password docs in `DEVELOPMENT.md`, `.dockerignore`, CircleCI `no_output_timeout`.
3. **Skip by default** (common false positives on sync):
   - **Overcommit / Yamllint:** RuboCop, Sorbet, Solargraph, Brakeman, Fasterer, BundleAudit, prepush Rake targets; YamlLint `sorbet/**` or `rbs_collection.lock.yaml` ignores; app-only Solargraph paths.
   - **CircleCI:** `checkout: method: full`, `pwd` in setup, cache keys on `*.gemspec` or app-specific filenames.
   - **`fix.sh`:** `ensure_rugged_packages_installed` (**Ruby repos only**, e.g. `cookiecutter-gem` — undercover), `ensure_handlebars_engine_packages_installed`, `ensure_mini_racer_packages_installed`, `ensure_chromedriver_correct_platform` — none of these belong in this **generic** language cookiecutter template or meta nested copies.
   - **App tree:** `Makefile`, `Gemfile`, `lib/`, filled `config/env.1p`, `PATH_add script` when `script/` is absent here.

Record the reference repo’s `origin/main` SHA in the PR (omit the private repo name from public text); diff with `git show origin/main:<path>` only.

### `.envrc` and `PATH_add`

- Only `PATH_add` directories that **exist in this template** (typically `bin/` when `bin/` is present).
- If a reference `.envrc` uses `PATH_add script` (or similar) and **this repo has no `script/`**, do not copy it here — add it in the descendant cookiecutter that owns `script/`.
- Missing referenced path → treat as **descendant** material (see `template-hierarchy.mdc`).

## Nested cookiecutter directory (optional)

If this template still contains a nested `{{cookiecutter.project_slug}}//` tree (generator meta-pattern), propagate shared boilerplate there only when that nested tree is the **same** tier. Do not blindly duplicate `.cursor/` into nested paths when the nested template is a different hierarchy level.

Propagate doc changes to sibling cookiecutter templates with `make update_from_cookiecutter` (or merge from the ancestor template’s `cookiecutter-template` branch).

## Checklist

1. `git fetch origin main` in every repo involved
2. List SHAs; diff only `git show origin/main:...`
3. Classify each change: this tier vs ancestor vs descendant
4. Run this repo’s tests
5. Confirm nothing came from unpushed local-only paths
