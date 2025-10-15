# Task 009: Documentation and Polish

**Status:** `not-started`
**Created:** 2025-10-15
**Depends On:** `005, 006, 007, 008` (all feature tasks)
**Can Be Parallelized:** No

---

## Goal

Complete comprehensive documentation, polish the codebase, and prepare for Hex.pm release.

---

## Context

This final task ensures the package is well-documented, tested, and ready for public use. All features should be complete before starting this task.

For reference, the originial `poflow` implementation in go can be found at: ~/code/poflow

---

## Deliverables

- [ ] Complete README.md
- [ ] CHANGELOG.md
- [ ] LICENSE file
- [ ] All @moduledoc written
- [ ] All @doc written
- [ ] All @spec type specifications
- [ ] ExDoc generated and reviewed
- [ ] Hex.pm metadata complete
- [ ] Contributing guide (optional)
- [ ] Example Phoenix integration

---

## Implementation Notes

### Key Decisions
- Use readme-new.md as the base for README.md
- Follow semantic versioning (start at 0.1.0)
- MIT License
- Comprehensive examples in documentation

### README.md Structure
Based on readme-new.md, include:
1. Project overview and features
2. Why gettext_ops? (token efficiency for AI)
3. Installation instructions
4. Quick start guide
5. Configuration section
6. Commands documentation (all 5 commands)
7. Usage examples and workflows
8. LLM integration guide
9. Troubleshooting section
10. Links and references

### CHANGELOG.md Format
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-10-15

### Added
- Initial release
- `mix gettext_ops.list_untranslated` command
- `mix gettext_ops.search` command
- `mix gettext_ops.search_value` command
- `mix gettext_ops.translate` command
- `mix gettext_ops.change_msgid` command
- JSON output support for all commands
- LLM-friendly stdin/stdout patterns
```

### Documentation Checklist

**Module Documentation:**
- [ ] `GettextOps` - Main module with overview
- [ ] `GettextOps.Config` - Configuration guide
- [ ] `GettextOps.Parser` - Parsing details
- [ ] `GettextOps.Entry` - Entry helpers
- [ ] `GettextOps.Writer` - Writer details
- [ ] `GettextOps.Output` - Output formats
- [ ] All operation modules
- [ ] All Mix tasks

**Function Documentation:**
- [ ] All public functions have @doc
- [ ] All public functions have @spec
- [ ] Examples in @doc where helpful
- [ ] Doctests for simple functions

### ExDoc Configuration
```elixir
# In mix.exs
defp docs do
  [
    main: "GettextOps",
    extras: ["README.md", "CHANGELOG.md"],
    source_url: "https://github.com/xnilsson/gettext_ops",
    source_ref: "v#{@version}",
    groups_for_modules: [
      "Operations": [
        GettextOps.Operations.ListUntranslated,
        GettextOps.Operations.Search,
        GettextOps.Operations.SearchValue,
        GettextOps.Operations.Translate,
        GettextOps.Operations.ChangeMsgid
      ],
      "Mix Tasks": [
        Mix.Tasks.GettextOps.ListUntranslated,
        Mix.Tasks.GettextOps.Search,
        Mix.Tasks.GettextOps.SearchValue,
        Mix.Tasks.GettextOps.Translate,
        Mix.Tasks.GettextOps.ChangeMsgid
      ]
    ]
  ]
end
```

### Code Polish
- [ ] Run `mix format`
- [ ] Run `mix credo` (if using)
- [ ] Check for compiler warnings
- [ ] Review all error messages
- [ ] Ensure consistent naming
- [ ] Remove debug code

---

## Testing Requirements

### Final Testing
- [ ] Run full test suite: `mix test`
- [ ] Check test coverage
- [ ] Test all commands manually
- [ ] Test in a real Phoenix project
- [ ] Test LLM workflow (stdin patterns)

### Manual Testing Checklist
```bash
# 1. List untranslated
mix gettext_ops.list_untranslated --locale sv
mix gettext_ops.list_untranslated --locale sv --json --limit 5

# 2. Search
mix gettext_ops.search "Welcome" --locale sv
mix gettext_ops.search "^Error" --locale sv --regex

# 3. Search value
mix gettext_ops.search_value "Välkommen" --locale sv

# 4. Translate
mix gettext_ops.translate --locale sv <<EOF
Sign In = Logga in
Welcome = Välkommen
EOF

# 5. Change msgid
mix gettext_ops.change_msgid --dry-run "Old" "New"
mix gettext_ops.change_msgid "Old" "New"
```

---

## Acceptance Criteria

- [ ] README.md complete and accurate
- [ ] CHANGELOG.md created
- [ ] LICENSE file added
- [ ] All modules documented
- [ ] All functions documented
- [ ] ExDoc builds without warnings
- [ ] `mix hex.build` succeeds
- [ ] All tests passing
- [ ] Code formatted
- [ ] No compiler warnings
- [ ] Manually tested in Phoenix project

---

## Progress Log

_Updates will be added here as work progresses_

---

## Related Files

- `README.md`
- `CHANGELOG.md`
- `LICENSE`
- `mix.exs` (documentation section)
- All `lib/**/*.ex` files (for @doc and @spec)

---

## References

- readme-new.md (source material)
- Hex documentation guide: https://hex.pm/docs/publish
- ExDoc guide: https://hexdocs.pm/ex_doc/readme.html
- Writing Documentation: https://hexdocs.pm/elixir/writing-documentation.html
