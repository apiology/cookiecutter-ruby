# Development

## fix.sh

If you want to use rbenv/pyenv/etc to manage versions of tools,
there's a `fix.sh` script which may be what you'd like to install
dependencies. It sets `git config core.hooksPath .githooks` so tracked
bootstrap hooks apply to this repo and all its worktrees.

## Git hooks and worktrees

Bootstrap hooks live in `.githooks/` (plain bash, not Overcommit) so
`post-checkout` can run `direnv exec . ./fix.sh` on clone or
`git worktree add` before Ruby and Bundler are ready. `fix.sh` uses
helpers under `bin/`; direnv (via `.envrc`) puts `bin/` on `PATH`.

For a fresh clone with automatic bootstrap on checkout:

```sh
git clone -c core.hooksPath=.githooks <url>
```

Otherwise run `direnv exec . ./fix.sh` once after clone (or `./fix.sh` if
you have no `.envrc`) — it sets `core.hooksPath` for future worktrees.

After `git worktree add`, `.githooks/post-checkout` runs
`direnv exec . ./fix.sh` automatically when the main checkout has already
run bootstrap at least once. It writes `.ruby-version` (gitignored) and
runs `bundle install`,
so the worktree's Ruby and bundler match the main checkout. Skipping
bootstrap can cause overcommit signature mismatches even after
re-signing — see
[.cursor/rules/overcommit-signing.mdc](.cursor/rules/overcommit-signing.mdc).

## Overcommit

This project uses [overcommit](https://github.com/sds/overcommit) for
quality checks on pre-commit, pre-push, and related hooks.
`.overcommit.yml` sets `gemfile: Gemfile` so those git hooks use the
same Bundler-managed gem as `bin/overcommit`.  `bundle exec overcommit --install`
will install hooks under `core.hooksPath`. Post-checkout bootstrap is
handled by `.githooks/post-checkout`, not Overcommit.

If a commit fails with overcommit **plugin signature** or **security**
messages, run both sign commands before retrying (see
`.cursor/rules/overcommit-signing.mdc`):

```sh
bin/overcommit --sign
bin/overcommit --sign pre-commit
```

## direnv

This project uses direnv to manage environment variables used during
development.  See the `.envrc` file for detail.

### Secrets: `config/env.1p` and 1Password

`config/env.1p` in git is the **template**: each variable points at a vault
item with an `op://` [secret
reference](https://developer.1password.com/docs/cli/secret-reference), not a
plaintext value.  Load order and fallbacks are in **`.envrc`**.  Mount
**resolved** values at **`config/env.local`** (below); use **`config/env.1p`**
in git when adding or syncing `op://` keys.

For local development, you can also store **resolved** values in a
[1Password Environment](https://developer.1password.com/docs/environments/) and mount
them as a [local `.env`
file](https://developer.1password.com/docs/environments/local-env-file/) at
**`config/env.local`** (macOS beta; fifo mount, gitignored).  Do **not**
mount at `config/env.1p` — that path is the tracked `op://` template and
conflicts with git.  When vault items change or you add keys to the template,
refresh the Environment with `op inject` and the 1Password app.

#### Prerequisites (macOS)

* [1Password for Mac](https://1password.com/downloads/mac/) with **Developer**
  turned on (Settings → Developer).
* [1Password CLI](https://developer.1password.com/docs/cli/get-started/):
  `brew install 1password-cli`
* Signed in: `op signin` (or 1Password app integration enabled).
* 1Password unlocked when you run `op inject`.

#### One-time: Environment and local mount

1. Open 1Password → **Developer** → **View Environments**.
2. Open (or create) the environment for this repo.
3. Under **Destinations**, add **Local .env file** and set the path to this
   repo’s **`config/env.local`** (use an absolute path, e.g.
   `$PWD/config/env.local` from the repo root).
4. Approve access when prompted; keep 1Password running while developing.

| Path | Role |
|------|------|
| `config/env.1p` | Git-tracked template (`op://` references); `make config/env` |
| `config/env.local` | 1Password Environment mount (resolved literals); see `.envrc` |

Do not commit `config/env.local`.

#### Update the Environment from `config/env.1p` (`op inject`)

Use this when you have changed `config/env.1p` in git (new variables or
updated `op://` paths) or when secrets in 1Password vaults have changed and
you want the Environment to match current vault values.

1. From the repo root, resolve the template to a **temporary** file (never
   write injected secrets back onto the tracked `config/env.1p`):

   ```sh
   op inject -i config/env.1p -o /tmp/repo-env.import -f
   ```

2. Confirm every reference resolved (no `op://` left):

   ```sh
   grep 'op://' /tmp/repo-env.import && echo 'ERROR: unresolved references' || echo 'OK'
   ```

3. Import into 1Password, then `rm /tmp/repo-env.import`.

4. If you use a local mount at `config/env.local`, confirm
   `grep -c op:// config/env.local` is **0**, then `direnv allow`.

#### Avoid duplicate variables

1Password Environments allow **multiple entries with the same name**.  The
mounted `config/env.local` will then mix `op://` lines with resolved values,
and `.envrc` will fail its `op://` check.  **Clean reset:** delete all
variables in the Environment, `op inject` once, import that file, and confirm
`grep -c op:// config/env.local` is **0**.

## Syncing boilerplate

See [docs/SYNCING_BOILERPLATE.md](docs/SYNCING_BOILERPLATE.md). Skill: `.cursor/skills/apiology-boilerplate-sync/`. Rules: `boilerplate-sync.mdc`, `template-hierarchy.mdc`, `overcommit-signing.mdc` — interpret hierarchy at **this** tier (`cookiecutter-ruby`, Ruby).

## Conventions

* Cursor authoring policy: `~/.cursor/rules/cursor-rule-authoring.mdc` only (global).
* Repo rules: clear task `description`, `alwaysApply: false`, optional `globs` only when they cover every auto-attach case.

## Tests

To get full realtime output from tests to debug e.g. slowness issues:

```sh
pytest tests/test_bake_project.py --capture=no -k test_bake_and_run_build
```

You can debug overall test timings with:

```sh
time pytest tests/test_bake_project.py --durations=0
```

It's also useful to replace 'make test' with something that will give
you real-time stdout/stderr in `test_bake_project.py`.

You can then wrap `time` commands around different things that shell
out, or do [this type of
technique](https://stackoverflow.com/a/1557584/2625807) for things
which aren't a simple shell-out.
