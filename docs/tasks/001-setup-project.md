# Task 001: Setup Project

**Status:** `not-started`
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
- [ ] `mix.exs` configured with proper metadata for Hex
- [ ] Dependencies added: `expo`, `ex_doc` (JSON support built-in to Elixir 1.18+)
- [ ] Basic directory structure created
- [ ] Git repository initialized (if not already)
- [ ] Initial `.formatter.exs` configured
- [ ] Test fixtures directory created

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
- [ ] Basic `mix test` runs successfully
- [ ] Test helper properly configured

### Test Fixtures
- [ ] Create `test/fixtures/test.po` with sample entries
- [ ] Create `test/fixtures/empty.po` with untranslated entries
- [ ] Create `test/fixtures/multiline.po` with multi-line msgid/msgstr

---

## Acceptance Criteria

- [ ] `mix deps.get` successfully installs all dependencies
- [ ] `mix compile` completes without warnings
- [ ] `mix test` runs (even if no real tests yet)
- [ ] `mix format --check-formatted` passes
- [ ] Project structure matches planned layout
- [ ] Hex metadata properly configured in mix.exs

---

## Progress Log

### 2025-10-15 - Initial Setup
- Project created with `mix new gettext_ops`
- Directory structure partially in place
- Need to complete mix.exs configuration and test fixtures

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
