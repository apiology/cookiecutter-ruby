# Solargraph issue catalog

Quick lookup for strong-level messages seen in Ruby gem repos and the preferred response.

## Unneeded @sg-ignore comment

**Cause:** Stale ignore after Solargraph upgrade, or `@sg-ignore` text in a non-directive comment.

**Fix:** Remove the `# @sg-ignore` line. Reword comments that mention `@sg-ignore` literally.

## Missing @return tag for Class#method

**Cause:** Strong level requires YARD return tags on documented methods.

**Fix:** Add `# @return [void]` for test helpers and side-effect methods; use an accurate type elsewhere. After bulk adds, run `rubocop -A` for comment indentation.

## Wrong argument type … expected String, received String, Symbol

**Cause:** CLI/options pass symbols; YARD on callee only documents `String`.

**Fix:** Widen `@param` to `[String, Symbol]` on the method definition (and upstream if the error moves).

## Unresolved call to @tasks / @timelines / @custom_fields

**Cause:** Subclass uses ivars; Solargraph only knows documented accessors.

**Fix:** Add `attr_reader` with `@return` types on the base class; call `tasks` not `@tasks`.

## Unresolved call to flag / action (GLI)

**Cause:** GLI block DSL has no RBI.

**Fix:** `# @sg-ignore` on the line immediately before each `c.flag` / `c.action`.

## Unresolved call to name= / add_dependency (gemspec)

**Cause:** `Gem::Specification` dynamic API.

**Fix:** One `# @sg-ignore` per assignment line in `*.gemspec`.

## Not enough arguments to Date.new

**Cause:** RBS 4 / Solargraph stricter `Date.new` signature.

**Fix:** `Date.parse('YYYY-MM-DD')` or `@sg-ignore` on that line.

## Declared return type … does not match inferred type … nil

**Cause:** Method raises on nil but Solargraph does not narrow (common for `*_or_raise` helpers).

**Fix:** `# @sg-ignore` on the method line with a short reason, or refactor to explicit early return with typed local.

## Return type could not be inferred

**Cause:** Last expression type opaque (e.g. `hash.keys.any? { … }`).

**Fix:** Add explicit `return`, cast with `@type`, or `# @sg-ignore` on the `def` line if `@return [Boolean]` is already documented.

## Unresolved call to success? / stdout (Overcommit)

**Cause:** `execute` return type unknown.

**Fix:** `# @type [Overcommit::Subprocess::Result]` on the assignment line.

## Unresolved call to [] on RBS::Unnamed::ENVClass (binstubs)

**Cause:** `$LOAD_PATH`-style special typing in binstubs.

**Fix:** Usually ignorable on the `ENV['BUNDLE_GEMFILE']` line; binstubs are often excluded or get a single ignore.

## Unresolved call to fetch on RBS::Unnamed::ENVClass

**Cause:** Strong-level RBS typing for `ENV` may not expose `fetch` in all contexts.

**Fix:** Add a targeted `# @sg-ignore` immediately above `ENV.fetch(...)` when a cleaner type annotation does not resolve it.

## Unresolved constant WARN

**Cause:** Bare severity constants in logger subclasses are not always resolved.

**Fix:** Use `Logger::WARN` (or explicit `Logger::Severity::<LEVEL>`).

## Wrong argument type for Float#/: arg_0 expected BigDecimal, received Integer

**Cause:** Numeric division in duration math can be inferred through strict numeric signatures.

**Fix:** Prefer `fdiv` (`seconds.fdiv(60)`) or make the divisor/value explicit float where appropriate.

## Unresolved call to join on Array<String>, nil

**Cause:** Exception backtrace is nullable (`nil` when missing).

**Fix:** Wrap with `Array(...)`: `Array(error.backtrace).join("\n")`.

## Wrong argument type … Mocha::Mock

**Cause:** Test mocks in spec/feature/test files.

**Fix:** Exclude mock-heavy test paths in `.solargraph.yml` (`spec/**/*`, `feature/**/*`, or `test/**/*`); do not strong-typecheck tests.

## Performance note

Do not loop `.cursor/skills/solargraph-typecheck/scripts/apply_solargraph_typecheck.rb` dozens of times — ignores only cover the next line, so automated passes can add/remove in oscillation. Triage by file, fix `lib/` properly, exclude tests, then use targeted ignores.
