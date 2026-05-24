---
name: solargraph-typecheck
description: >-
  Fix Solargraph typecheck issues, run "make solargraph", update @sg-ignore
  comments, resolve strong/typed typecheck failures, or work on YARD typing
  after a Solargraph upgrade in this Ruby gem.
version: 1.0.0
---

# Solargraph typecheck

Resolve Solargraph problems in this repo without re-learning project conventions each time.

## Environment

Always run project tooling through **direnv** so `.envrc` loads secrets and `bin/` is on `PATH`:

```bash
direnv allow
direnv exec . ./fix.sh          # first-time / cold setup
direnv exec . make build-typecheck
direnv exec . make solargraph-strong
```

- `./fix.sh` needs `bin/install_package` and friends; do not run bare `./fix.sh` without direnv.
- `make build-typecheck` depends on `.ruby-version`, yard/tapioca artifacts, `rbi/{{cookiecutter.project_slug}}.rbi`, and updates the RBS gem collection via `bin/rbs collection update`.

## Which level to use

| Target | Command | Notes |
|--------|---------|-------|
| Local default | `make solargraph-strong` | Same as `make solargraph`; must be clean |
| CI | `make ci-solargraph` | Strong level; see `Makefile` |
| Full gate | `make typecheck` | Sorbet + Solargraph strong |

## Scope

See `.solargraph.yml` for include/exclude paths and reporter settings. Mock-heavy test directories (`spec/`, `feature/`, or `test/`) are often excluded from strong typecheck — add paths under `exclude:` rather than thousands of per-line ignores in tests.

## Workflow

1. Run `direnv exec . make build-typecheck` if pins/RBI/RBS collection may be stale.
2. Run `direnv exec . make solargraph-strong 2>&1 | tee /tmp/sg-typecheck.txt`.
3. Triage by message type (see below): fix easy issues first, then targeted `@sg-ignore`.
4. Re-run until zero problems.
5. Run `direnv exec . bin/rubocop` — bulk `@return [void]` or layout fixes often need `rubocop -A`.

Optional helpers (use after manual triage, not as a blind hammer):

```bash
direnv exec . bundle exec solargraph typecheck --level strong 2>&1 | tee /tmp/sg-typecheck.txt
ruby .cursor/skills/solargraph-typecheck/scripts/apply_solargraph_typecheck.rb /tmp/sg-typecheck.txt
ruby .cursor/skills/solargraph-typecheck/scripts/strip_sg_ignore.rb path/to/file_or_dir.rb
```

## `@sg-ignore` rules (Solargraph 0.59+)

- Applies to the **next AST node only** — one ignore per statement (or put ignore immediately before the failing line).
- **Unneeded @sg-ignore** means remove that comment; Solargraph 0.59 reports stale ignores after upgrades.
- Do **not** write the literal text `@sg-ignore` in normal comments or file headers — Solargraph treats it as a directive (`Unneeded @sg-ignore` on unrelated lines). Say "ignore comment" in prose instead.
- Prefer **fixes** over ignores when cheap (YARD `@param`, `String(...)`, `attr_reader`, nil guards).

## Fix patterns (prefer these over ignores)

### YARD `@param` widening

CLI and option helpers may accept symbols from [GLI](https://github.com/davydovanton/gli) (Gem Library Interface) defaults. When strong reports `expected String, received String, Symbol`, widen the callee's `@param`:

```ruby
# @param workspace_name [String, Symbol]
```

Propagate along call chains as errors move upstream.

### Use accessors instead of `@ivar` in subclasses

If a base class defines `@tasks` in `initialize`, add documented `attr_reader`s and call `tasks`, not `@tasks`, in subclasses.

### Nil narrowing

Solargraph often ignores `raise` guards. Options:

- Explicit `@type [SomeClass]` after guard, or
- `# @sg-ignore nil check above is not flow-sensitive` on the next line.

### `Date.new` vs RBS 4

Strong may report `Not enough arguments to Date.new` for `Date.new(2029, 1, 4)`. Prefer:

```ruby
Date.parse('2029-01-04')
```

### Duck types and unknown stdlib

- HTTP response bodies: `@param response [#read_body]`
- `$LOAD_PATH`: one `# @sg-ignore` on the bootstrap line (special RBS typing)
- Bundler binstub `ENV['BUNDLE_GEMFILE'] ||= ...`: YARD stubs in `config/annotations_misc.rb` do not override RBS `ENVClass` at strong level — keep `# @sg-ignore` on each binstub line

### GLI command blocks

Solargraph does not see `c.flag` / `c.action`. Put `# @sg-ignore` **immediately before each** `c.flag` / `c.action` line inside the block (one ignore does not cover the whole block).

### `Gem::Specification` in `*.gemspec`

Dynamic setters are invisible to Solargraph. Use one `# @sg-ignore` per `spec.*` / `add_dependency` line (and the `$LOAD_PATH` line).

### Overcommit hooks

Subprocess results need an explicit type:

```ruby
# @type [Overcommit::Subprocess::Result]
result = execute(...)
```

### Predicate methods returning Boolean

Methods that return `true`/`false` but mutate state may trigger RuboCop `Naming/PredicateMethod` if named `fix_*!`. For maintenance scripts, use a scoped `# rubocop:disable` block rather than renaming call sites.

## When to ignore

Use `@sg-ignore` for:

- GLI DSL, gemspec DSL, Mocha-heavy code (prefer `.solargraph.yml` exclude for tests instead)
- Inferred return type on simple `any?` / `include?` blocks where YARD already says `@return [Boolean]`
- Third-party API fields without complete RBI pins

Avoid:

- Blanket `@sg-ignore` in test files (use `.solargraph.yml` exclude)
- Chained `@sg-ignore` on lines that no longer fail (causes **Unneeded @sg-ignore**)
- Mass automated ignore insertion without re-running typecheck (creates ignore/remove oscillation)

## `script/` files

Scripts under `script/` should be **typed** (`# typed: true`) when typechecked:

- Use a small class instead of `Struct` for YARD clarity.
- Document all methods with `@param` / `@return`.
- Avoid `@sg-ignore` in comments that are not actual directives.

## Rubocop fallout

After adding many `# @return [void]` lines in tests (historical) or editing scripts:

```bash
direnv exec . bin/rubocop -A
```

Watch for `Lint/DuplicateMethods` when a test class both `def_delegators :@mocks, :foo` and defines `def foo`.

## Success criteria

```bash
direnv exec . make solargraph-strong   # 0 problems
direnv exec . bin/rubocop              # no offenses
```

## Additional resources

- **`references/issue-catalog.md`** — common Solargraph messages and responses
- **`scripts/apply_solargraph_typecheck.rb`** — parse typecheck output and apply targeted fixes
- **`scripts/strip_sg_ignore.rb`** — bulk-remove standalone `# @sg-ignore` lines
