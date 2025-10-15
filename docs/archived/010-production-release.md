# Task 010: Production Release and CI/CD

**Status:** `in-progress`
**Created:** 2025-10-15
**Depends On:** `009` (documentation must be complete)
**Can Be Parallelized:** No

---

## Goal

Set up CI/CD pipelines, ensure code quality standards are met, and publish the package to Hex.pm for production use.

---

## Context

Before releasing gettext_ops to the public, we need to ensure:
1. Automated testing and quality checks via CI/CD
2. Code meets strict quality standards (Credo, Dialyzer)
3. Package is properly configured for Hex.pm
4. Release process is documented

This task makes the project production-ready and establishes quality gates for future contributions.

---

## Deliverables

### CI/CD Setup
- [ ] Copy and adapt `.github/workflows/ci.yml` from ~/code/live_svelte_gettext
- [ ] Configure test job with Elixir/OTP matrix
- [ ] Add format checking step
- [ ] Add Credo strict checking step
- [ ] Add Dialyzer step
- [ ] Add coverage reporting (optional but recommended)

### Code Quality Dependencies
- [ ] Add `credo` to dev dependencies in mix.exs
- [ ] Add `dialyxir` to dev dependencies in mix.exs
- [ ] Add `excoveralls` to dev/test dependencies (optional)
- [ ] Run `mix deps.get` to install new dependencies

### Credo Compliance
- [ ] Create `.credo.exs` config file
- [ ] Run `mix credo --strict` and fix all issues
- [ ] Ensure no warnings or errors remain
- [ ] Document any disabled checks with justification

### Dialyzer Compliance
- [ ] Run `mix dialyzer` (first run generates PLT)
- [ ] Fix all type warnings and errors
- [ ] Add missing `@spec` annotations
- [ ] Ensure all return types are correct

### Hex.pm Publication
- [ ] Verify `mix.exs` package metadata is complete
- [ ] Ensure LICENSE file exists (MIT)
- [ ] Verify README.md is comprehensive
- [ ] Run `mix hex.build` to check package
- [ ] Create Hex.pm account if needed
- [ ] Run `mix hex.publish` to publish package
- [ ] Verify package appears on Hex.pm
- [ ] Test installation in separate project

### Git Tagging and Release
- [ ] Create git tag for v0.1.0
- [ ] Push tag to GitHub
- [ ] Create GitHub release with changelog
- [ ] Link Hex.pm package in GitHub release

---

## Implementation Notes

### Key Decisions
- Use strict Credo checks to maintain high code quality
- Follow Elixir 1.18+ conventions
- Target OTP 27 as primary version
- Use semantic versioning starting at 0.1.0

### CI/CD Pipeline Structure
Copy from `~/code/live_svelte_gettext/.github/workflows/ci.yml` and adapt:
- Test job: format, test, credo, dialyzer
- Coverage job: generate HTML coverage report (optional)
- Run on push to main and all PRs

### Required Dependencies

Add to `mix.exs`:
```elixir
defp deps do
  [
    {:expo, "~> 1.1"},
    {:ex_doc, "~> 0.31", only: :dev, runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    {:excoveralls, "~> 0.18", only: :test}  # Optional
  ]
end
```

### Credo Configuration

Create `.credo.exs`:
```elixir
%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      checks: [
        # Enable all default checks
        {Credo.Check.Readability.ModuleDoc, []},
        {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
        # Disable checks if needed (with justification)
        # {Credo.Check.Design.AliasUsage, false}
      ]
    }
  ]
}
```

### Dialyzer Setup

First run will take time to build PLT:
```bash
mix dialyzer
```

Add to `mix.exs` project config:
```elixir
dialyzer: [
  plt_add_apps: [:mix, :ex_unit],
  plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
  flags: [:error_handling, :underspecs]
]
```

### Publishing to Hex.pm

Pre-flight checks:
```bash
# 1. Verify package builds
mix hex.build

# 2. Check package contents
unzip -l gettext_ops-0.1.0.tar

# 3. Publish (will prompt for confirmation)
mix hex.publish
```

### Release Checklist
1. Ensure all tests pass: `mix test`
2. Format code: `mix format`
3. Check with Credo: `mix credo --strict`
4. Check with Dialyzer: `mix dialyzer`
5. Build docs: `mix docs`
6. Build package: `mix hex.build`
7. Commit all changes
8. Tag release: `git tag v0.1.0`
9. Push: `git push && git push --tags`
10. Publish: `mix hex.publish`
11. Create GitHub release

---

## Testing Requirements

### CI/CD Testing
- [ ] CI pipeline runs successfully on push
- [ ] All jobs pass (test, format, credo, dialyzer)
- [ ] Coverage report generates (if enabled)
- [ ] Pipeline runs on PRs

### Manual Testing
- [ ] Run all commands in CI pipeline locally
- [ ] Verify `mix hex.build` succeeds
- [ ] Test package installation in clean project
- [ ] Verify documentation builds correctly
- [ ] Check ExDoc output is readable

### Integration Testing
```bash
# In a separate Phoenix project
mix new test_project --app test_app
cd test_project

# Add to mix.exs
{:gettext_ops, "~> 0.1.0"}

mix deps.get
mix gettext_ops.list_untranslated --locale en
```

---

## Acceptance Criteria

- [ ] GitHub Actions CI/CD pipeline configured and passing
- [ ] `mix format --check-formatted` passes
- [ ] `mix test` passes with 100% success
- [ ] `mix credo --strict` passes with no issues
- [ ] `mix dialyzer` passes with no warnings
- [ ] `mix hex.build` succeeds without errors
- [ ] Package published to Hex.pm
- [ ] Git tag v0.1.0 created and pushed
- [ ] GitHub release created with changelog
- [ ] Package installable in external projects
- [ ] All documentation builds correctly
- [ ] CI pipeline runs automatically on commits

---

## Progress Log

### 2025-10-15 - Started Task 010
- Status changed to in-progress
- Beginning CI/CD setup and code quality improvements
- All dependencies (task 009) are complete

### 2025-10-15 - Quality Tools Setup Complete
- Added credo, dialyxir, and excoveralls to mix.exs dependencies
- Created .credo.exs configuration with strict checking enabled
- Configured Dialyzer with PLT caching to priv/plts/
- Added test coverage configuration for ExCoveralls

### 2025-10-15 - Fixed All Quality Issues
- **Credo**: Fixed module attribute ordering (shortdoc, moduledoc, use)
- **Credo**: Refactored nested functions to reduce complexity from 4 to 2 levels
- **Credo**: All 33 source files now pass strict checks (0 issues)
- **Dialyzer**: Fixed 3 contract_supertype warnings by tightening type specs
- **Dialyzer**: Replaced generic `term()` with specific error types
- **Dialyzer**: All modules pass type checking with no warnings

### 2025-10-15 - CI/CD Pipeline Created
- Copied and adapted CI workflow from live_svelte_gettext
- Added test job with Elixir 1.18 / OTP 27 matrix
- Added coverage job with artifact upload
- Configured PLT caching for faster Dialyzer runs
- Added build caching for dependencies and compilation

### 2025-10-15 - Package Metadata Finalized
- Updated .gitignore to exclude PLT files (machine-specific artifacts)
- Configured explicit file list in package() to exclude build artifacts
- Verified package builds cleanly with `mix hex.build`
- All tests passing (18 doctests, 297 tests, 0 failures)

---

## Related Files

- `.github/workflows/ci.yml` (new)
- `.credo.exs` (new)
- `mix.exs` (update dependencies and dialyzer config)
- All `lib/**/*.ex` files (ensure specs and docs)
- All `test/**/*_test.exs` files (ensure coverage)

---

## References

- Reference CI setup: `~/code/live_svelte_gettext/.github/workflows/ci.yml`
- Hex publishing guide: https://hex.pm/docs/publish
- Credo documentation: https://hexdocs.pm/credo
- Dialyxir documentation: https://hexdocs.pm/dialyxir
- GitHub Actions for Elixir: https://github.com/erlef/setup-beam
- Excoveralls: https://hexdocs.pm/excoveralls
- Semantic Versioning: https://semver.org

---

## Notes

- First Dialyzer run will be slow (builds PLT)
- Consider caching PLT in CI for faster builds
- Hex.pm publication is permanent - double-check version before publishing
- Can use `mix hex.publish --dry-run` to test publication
- May need to configure `HEX_API_KEY` in GitHub Actions for automated releases
