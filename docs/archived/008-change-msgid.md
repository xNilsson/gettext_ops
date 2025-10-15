# Task 008: Change Msgid Command

**Status:** `completed`
**Created:** 2025-10-15
**Completed:** 2025-10-15
**Depends On:** `002, 003, 004`
**Can Be Parallelized:** Yes (parallel with 005, 006, 007)

---

## Goal

Implement the change_msgid command to update source text (msgid) across all .po files, .pot templates, and optionally source code references.

---

## Context

When developers want to change the source text (msgid), they need to update it everywhere:
- All locale .po files (preserve existing translations!)
- .pot template files
- Optionally: source code references

This command automates that tedious process while keeping translations intact.

For reference, the originial `poflow` implementation in go can be found at: ~/code/poflow

---

## Deliverables

- [ ] `GettextOps.Operations.ChangeMsgid` module
- [ ] `mix gettext_ops.change_msgid` task
- [ ] Update all .po files
- [ ] Update .pot template files
- [ ] Preserve all translations (msgstr)
- [ ] Dry-run mode
- [ ] Detailed summary of changes
- [ ] Tests for all scenarios

---

## Implementation Notes

### Key Decisions
- Update msgid in all .po files across all locales
- Update msgid in .pot template file
- **Preserve existing translations** (msgstr remains unchanged)
- Preserve comments, references, flags
- Atomic updates (write to temp, then rename)
- Dry-run mode to preview changes
- Optional: Update source code references (if time permits)

### API Design

**Operation module:**
```elixir
defmodule GettextOps.Operations.ChangeMsgid do
  @doc "Change msgid across all translation files"
  @spec run(String.t(), String.t(), keyword()) ::
    {:ok, %{files_updated: integer(), entries_updated: integer()}} | {:error, term()}
  def run(old_msgid, new_msgid, opts)

  # opts: [domain: "default", dry_run: false]

  @doc "Update msgid in a single file"
  @spec update_file(String.t(), String.t(), String.t(), boolean()) ::
    {:ok, integer()} | {:error, term()}
  def update_file(file_path, old_msgid, new_msgid, dry_run)
end
```

**Mix task:**
```elixir
defmodule Mix.Tasks.GettextOps.ChangeMsgid do
  use Mix.Task

  @shortdoc "Change msgid across all locale files"

  @moduledoc """
  Update msgid (source text) across all .po and .pot files.

  ## Usage

      mix gettext_ops.change_msgid "Sign In" "Log In"

      # Preview changes first
      mix gettext_ops.change_msgid --dry-run "Sign In" "Log In"

  ## What It Does

  1. Finds all .po files in priv/gettext/*/LC_MESSAGES/
  2. Finds .pot template files
  3. Updates the msgid in all matching entries
  4. Preserves all translations (msgstr values remain intact)
  5. Shows summary of changes

  ## Options

    * `--dry-run` - Preview changes without modifying files
    * `--domain` / `-d` - Gettext domain (default: "default")
  """

  def run(args)
end
```

### CLI Usage Examples
```bash
# Update msgid everywhere
mix gettext_ops.change_msgid "Sign In" "Log In"

# Preview changes first
mix gettext_ops.change_msgid --dry-run "Sign In" "Log In"

# Specific domain
mix gettext_ops.change_msgid "Sign In" "Log In" --domain errors
```

### Update Process
```elixir
1. List all .po files using Config.list_po_files()
2. Find .pot file using Config.pot_file_path()
3. For each file:
   a. Parse with Expo
   b. Find messages matching old_msgid
   c. Update msgid to new_msgid (preserve msgstr!)
   d. Write to temp file
   e. Rename to original (atomic)
4. Return summary
```

### Dry-Run Output Example
```
Would update the following files:

✓ priv/gettext/sv/LC_MESSAGES/default.po (1 entry)
  msgid "Sign In" → "Log In"
  msgstr "Logga in" (preserved)

✓ priv/gettext/en/LC_MESSAGES/default.po (1 entry)
  msgid "Sign In" → "Log In"
  msgstr "" (preserved)

✓ priv/gettext/default.pot (1 entry)
  msgid "Sign In" → "Log In"

Would update 3 file(s) with 3 total entries
```

### Actual Update Output
```
Updated the following files:

✓ priv/gettext/sv/LC_MESSAGES/default.po (1 entry)
✓ priv/gettext/en/LC_MESSAGES/default.po (1 entry)
✓ priv/gettext/default.pot (1 entry)

Updated 3 file(s) with 3 total entries
```

---

## Testing Requirements

### Unit Tests
- [ ] Test updating msgid in single file
- [ ] Test preserving msgstr (translations)
- [ ] Test preserving comments
- [ ] Test preserving references
- [ ] Test dry-run mode (no file changes)
- [ ] Test msgid not found (graceful handling)
- [ ] Test updating multiple entries
- [ ] Test atomic updates

### Integration Tests
- [ ] Test updating across multiple locale files
- [ ] Test updating .pot file
- [ ] Test dry-run vs actual update
- [ ] Test summary output

### Test Fixtures
- Create fixture directory with multiple locales
- Include .pot template file

---

## Acceptance Criteria

- [ ] Updates msgid across all .po files
- [ ] Updates .pot template file
- [ ] Preserves all translations (msgstr)
- [ ] Preserves comments, references, flags
- [ ] Dry-run mode works
- [ ] Atomic updates (no corruption)
- [ ] Detailed summary printed
- [ ] All tests passing
- [ ] Command documented with @moduledoc and @shortdoc
- [ ] Functions documented with @doc and @spec

---

## Progress Log

### 2025-10-15 - Implementation Complete

**Implemented:**
- ✅ Created `GettextOps.Operations.ChangeMsgid` module with core logic
- ✅ Implemented `update_file/4` function for single file updates with atomic writes
- ✅ Implemented `run/3` function to update all .po and .pot files
- ✅ Added dry-run mode support
- ✅ Created `Mix.Tasks.GettextOps.ChangeMsgid` task with comprehensive documentation
- ✅ Wrote 19 unit tests for the operation module
- ✅ Wrote 27 integration tests for the Mix task
- ✅ All 298 tests + 19 doctests passing

**Key Features:**
- Updates msgid across all .po files in all locales
- Updates .pot template file
- Preserves all translations (msgstr values remain intact)
- Preserves comments, references, and flags
- Atomic file updates prevent corruption
- Dry-run mode for previewing changes
- Detailed summary output showing files and entries updated

**Testing:**
- Comprehensive test coverage with isolated test environments
- Tests verify msgid updates, msgstr preservation, atomic updates
- Integration tests properly isolated to avoid affecting other tests
- All edge cases covered: unicode, quotes, newlines, empty files, etc.

---

## Related Files

- `lib/gettext_ops/operations/change_msgid.ex`
- `lib/mix/tasks/gettext_ops.change_msgid.ex`
- `test/gettext_ops/operations/change_msgid_test.exs`
- `test/mix/tasks/gettext_ops.change_msgid_test.exs`

---

## References

- Example from readme-new.md lines 305-343
- Expo message update: https://hexdocs.pm/expo/Expo.Message.html
