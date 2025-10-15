# Task 001: Setup Project

**Status:** `completed`
**Created:** 2025-10-15
**Depends On:** `none`

---

## Goal

Set up the Elixir project structure with proper dependencies, configuration, and initial directory layout for gettext_ops.

---

## Context

This is the foundation task that prepares the project for all subsequent development. We're building a Hex package that provides Mix tasks for working with Phoenix Gettext .po files. The project uses Expo for parsing and should be configured for easy development and testing.

---

## Deliverables

- [x] Elixir project created with `mix new gettext_ops` (already done)
- [x] `mix.exs` configured with proper metadata for Hex
- [x] Dependencies added: `expo`, `ex_doc` (JSON support built-in to Elixir 1.18+)
- [x] Basic directory structure created
- [x] Git repository initialized (if not already)
- [x] Initial `.formatter.exs` configured
- [x] Test fixtures directory created

---

## Implementation Notes

### Key Decisions
- Use Expo ~> 1.1 for .po file parsing (same library Phoenix Gettext uses)
- Use built-in JSON module for JSON encoding/decoding (Elixir 1.18+)
- Support Elixir ~> 1.18 (includes built-in JSON support)

### Directory Structure
```
lib/
├── gettext_ops.ex                # Main public API
└── gettext_ops/
    ├── config.ex                 # Config handling
    └── operations/               # Operation modules

test/
├── gettext_ops_test.exs
├── fixtures/                     # Sample .po files
│   ├── test.po                  # Basic test file
│   ├── empty.po                 # Empty entries
│   └── multiline.po             # Multi-line entries
└── test_helper.exs
```

### Mix.exs Configuration
```elixir
defp deps do
  [
    {:expo, "~> 1.1"},
    {:ex_doc, "~> 0.31", only: :dev, runtime: false}
  ]
end

def project do
  [
    app: :gettext_ops,
    version: "0.1.0",
    elixir: "~> 1.18",
    description: "Targeted Mix tasks for Phoenix Gettext translations",
    package: package(),
    docs: docs(),
    # ...
  ]
end

defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/xnilsson/gettext_ops"},
    maintainers: ["Christopher Nilsson"]
  ]
end
```

---

## Testing Requirements

### Unit Tests
- [x] Basic `mix test` runs successfully
- [x] Test helper properly configured

### Test Fixtures
- [x] Create `test/fixtures/test.po` with sample entries
- [x] Create `test/fixtures/empty.po` with untranslated entries
- [x] Create `test/fixtures/multiline.po` with multi-line msgid/msgstr

---

## Acceptance Criteria

- [x] `mix deps.get` successfully installs all dependencies
- [x] `mix compile` completes without warnings
- [x] `mix test` runs (even if no real tests yet)
- [x] `mix format --check-formatted` passes
- [x] Project structure matches planned layout
- [x] Hex metadata properly configured in mix.exs

---

## Progress Log

### 2025-10-15 - Initial Setup
- Project created with `mix new gettext_ops`
- Directory structure partially in place
- Need to complete mix.exs configuration and test fixtures

### 2025-10-15 - Starting Implementation
- Beginning work on task 001
- Will configure mix.exs, add dependencies, create directory structure, and set up test fixtures

### 2025-10-15 - Task Completed
- Updated mix.exs with Hex metadata (maintainers, docs function)
- Dependencies already configured (expo ~> 1.1, ex_doc ~> 0.31)
- Created directory structure: lib/gettext_ops/operations/ and lib/gettext_ops/mix/tasks/
- Created test fixtures: test.po, empty.po, multiline.po with various entry types
- Verified all acceptance criteria:
  - mix deps.get: All dependencies installed successfully
  - mix compile: Clean compilation with no warnings
  - mix test: Tests run successfully (1 doctest, 1 test, 0 failures)
  - mix format --check-formatted: All code properly formatted
- Project ready for next phase of development

---

## Related Files

- `mix.exs`
- `test/test_helper.exs`
- `test/fixtures/*.po`
- `.formatter.exs`

---

## References

- Expo library: http://hex2txt.fly.dev/expo/llms.txt 
- Mix task guide: https://hexdocs.pm/mix/Mix.Task.html
- Hex package guide: https://hex.pm/docs/publish
