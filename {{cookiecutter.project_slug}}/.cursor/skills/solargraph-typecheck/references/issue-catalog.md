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

## Wrong argument type … Mocha::Mock

**Cause:** Test mocks in spec/feature/test files.

**Fix:** Exclude mock-heavy test paths in `.solargraph.yml` (`spec/**/*`, `feature/**/*`, or `test/**/*`); do not strong-typecheck tests.

## Performance note

Do not loop `.cursor/skills/solargraph-typecheck/scripts/apply_solargraph_typecheck.rb` dozens of times — ignores only cover the next line, so automated passes can add/remove in oscillation. Triage by file, fix `lib/` properly, exclude tests, then use targeted ignores.
