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

If the goal is "get N more files passing" rather than "zero errors everywhere", rank files by failure count and clear the smallest buckets first:

```bash
ruby -e 'h=Hash.new(0); File.foreach("/tmp/sg-typecheck.txt"){|l| if l =~ %r{^(/[^:]+\.rb):\d+\s-\s}; h[$1]+=1; end}; h.select{|_,c| c<=8}.sort_by{|f,c| [c,f]}.each{|f,c| puts "%3d #{f}" % c }'
```

Then compare before/after runs to count files that moved from `>0` errors to `0`.

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

### Prefer `config/annotations_*.rb` stubs for opaque stdlib / gem APIs

When Solargraph reports `Unresolved call to …` on a **stdlib or gem** method you do not own (e.g. `FileUtils.ln_sf`), prefer a YARD `@!parse` / `@!override` stub in `config/annotations_*.rb` (loaded via `.solargraph.yml` `include: config/annotations*.rb`) over a per-call-site `@sg-ignore`.

```ruby
# config/annotations_misc.rb
# @!override FileUtils.ln_sf
#   @param src [String]
#   @param dest [String]
#   @return [void]
#
# @!parse
#   module FileUtils
#     class << self
#       # @param src [String]
#       # @param dest [String]
#       # @return [void]
#       def ln_sf(src, dest, **options); end
#     end
#   end
```

**ENV caveat (Solargraph 0.59+):** do **not** add a YARD `class ENV` stub. Under strong, Solargraph **unions** pins for the `ENV` constant:

1. Stdlib RBS → `RBS::Unnamed::ENVClass` (has `[]` / `[]=` / `fetch`).
2. Ruby-core / constant pin → still includes a `Class<ENV>` view of the same top-level object.

Method lookup on a union requires the method on **every** member. `[]` exists on `ENVClass` but not on `Class<ENV>`, so strong reports unresolved calls even though RBS is correct. A YARD `class ENV` stub adds another pin and makes the union worse.

Prefer:

1. Remove any local `class ENV` YARD stub.
2. Keep normal `ENV[key]` / `ENV[key] = value` / `ENV.fetch(...)` call sites.
3. When strong reports unresolved `[]` / `[]=` / `fetch` on `RBS::Unnamed::ENVClass, Class<ENV>`, use a one-line `# @sg-ignore` with the exact error text (optional two-space continuation noting the union bug for upstream mining).
4. **Do not** use `ENV.send(:[], …)` / `ENV.send(:[]=, …)`. That only replaces conventional ENV access (which Solargraph rejects) with unconventional code that Solargraph happens not to flag — it does **not** typecheck any better, and reviewers reject it.

For `YAML.load_file`, strong will reject `# @type […]` on the assignment unless the method’s return type is known — stub `Psych.load_file` / `YAML.load_file` in `config/annotations_*.rb` returning `Object, nil`, then annotate the local with `# @type [Object, nil]`.

Only fall back to a one-line `# @sg-ignore` when an annotation stub does not take effect after re-running strong typecheck (some early boot / binstub paths still need ignores).

### Document unresolved parameters (including block params)

When Solargraph cannot resolve a call on a method or block parameter (`Unresolved call to …`), add a YARD `# @param` (or `# @type` on a local) for that parameter **before** reaching for `@sg-ignore`. Do this for **every** parameter on the failing call (including block params and `proc`/`lambda` args).

**Block params:** put `# @param` on the line(s) **immediately above** the iterator/`find_each`/`map` call — **never inside** the `do … end` / `{ … }` body. A tag after `do` is easy to write and usually ignored by Solargraph.

```ruby
# good — @param above the block
# @param record [SomeModel]
stale_records.each do |record|
  record.refresh
end

# bad — @param inside the block (do not do this)
stale_records.each do |record|
  # @param record [SomeModel]
  record.refresh
end
```

Prefer annotating the real method in-repo (`# @param` / `# @return` on the definition) over a parallel stub in `config/annotations_*.rb` when the method lives in this repository.

### Fix “return type could not be inferred” before `@sg-ignore`

When strong reports `Class#method return type could not be inferred` even with `# @return […]` present, **first** make the body inferable:

1. Assign the result to a local with `# @type […]` matching the `@return`, then return that local.
2. If the RHS method itself is undefined (e.g. `YAML.load_file`, opaque gem APIs), add a `config/annotations_*.rb` stub for that method’s return type, then retry.
3. Only then use `# @sg-ignore … return type could not be inferred` — and note in the ignore or a nearby comment if a stub was tried and failed.

```ruby
# @return [Hash{Symbol => Object}]
def metric_to_hash(metric)
  # @type [Hash{Symbol => Object}]
  result = metric.to_h.symbolize_keys
  result
end
```

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
- `ENV` / `FileUtils` / similar: prefer `config/annotations_*.rb` `@!parse` / `@!override` stubs where they help — see “Prefer config/annotations_*.rb stubs” above. Never add a YARD `class ENV` stub. For ENV `[]` / `[]=` / `fetch` union failures, keep normal `ENV[...]` + `# @sg-ignore`. Never `ENV.send` (unconventional code that Solargraph happens to ignore is not better typing)

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

### Common one-line strong fixes

- `Unresolved constant WARN` in logger wrappers: prefer `Logger::WARN` over bare `WARN`
- `Wrong argument type for Float#/: ... received Integer` in duration math: prefer `value.fdiv(60)` (or explicit float literal) when dividing numeric durations
- `Unresolved call to join on Array<String>, nil` for backtraces: use `Array(error.backtrace).join("\n")`
- Missing test method docs (`Missing @return tag for Test...#test_*`): add `# @return [void]`

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

## Sorbet (gradual typing, lib or test)

When Sorbet reports **Changing the type of a variable is not permitted in loops and blocks** on a local updated inside a block (callback, `yield`, etc.), initialize with an explicit type—e.g. `flag = T.let(false, T::Boolean)` before `flag = true` in the block.

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
