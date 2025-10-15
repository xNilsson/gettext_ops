# Task 005: Search Commands

**Status:** `completed`
**Created:** 2025-10-15
**Depends On:** `002, 003, 004`
**Can Be Parallelized:** Yes (parallel with 006, 007, 008)

---

## Goal

Implement search functionality for finding entries by msgid (source text) and msgstr (translated text) with regex support.

---

## Context

Users need to search for specific translation entries without opening large .po files. We provide two search commands:
1. `mix gettext_ops.search` - Search by msgid (source text)
2. `mix gettext_ops.search_value` - Search by msgstr (translated text)

Both support substring matching (case-insensitive) and regex patterns.

For reference, the originial `poflow` implementation in go can be found at: ~/code/poflow

---

## Deliverables

- [x] `GettextOps.Operations.Search` module
- [x] `GettextOps.Operations.SearchValue` module
- [x] `mix gettext_ops.search` task
- [x] `mix gettext_ops.search_value` task
- [x] Support for regex and substring matching
- [x] JSON and text output
- [x] Limit option
- [x] Tests for both search types

---

## Implementation Notes

### Key Decisions
- Default to case-insensitive substring matching
- Use `--regex` flag for regex patterns
- Support `--limit` to cap results
- Support `--locale` for specific language files
- Support `--json` for JSON output

### API Design

**Operation modules:**
```elixir
defmodule GettextOps.Operations.Search do
  @doc "Search for entries by msgid"
  @spec run(String.t(), keyword()) ::
    {:ok, [Expo.Message.t()]} | {:error, term()}
  def run(pattern, opts)

  # opts: [locale: "sv", regex: false, limit: nil, json: false]
end

defmodule GettextOps.Operations.SearchValue do
  @doc "Search for entries by msgstr"
  @spec run(String.t(), keyword()) ::
    {:ok, [Expo.Message.t()]} | {:error, term()}
  def run(pattern, opts)
end
```

**Mix tasks:**
```elixir
defmodule Mix.Tasks.GettextOps.Search do
  use Mix.Task

  @shortdoc "Search for entries by msgid (source text)"

  def run(args) do
    # Parse args with OptionParser
    # Call GettextOps.Operations.Search.run/2
    # Format and print output
  end
end
```

### CLI Usage Examples
```bash
# Search for "Welcome" in Swedish translations
mix gettext_ops.search "Welcome" --locale sv

# Regex search (entries starting with "Error")
mix gettext_ops.search "^Error" --locale sv --regex

# JSON output with limit
mix gettext_ops.search "button" --locale sv --json --limit 5

# Search in translations (msgstr)
mix gettext_ops.search_value "Välkommen" --locale sv
```

### Matching Logic
```elixir
# Substring (case-insensitive)
String.downcase(msgid) =~ String.downcase(pattern)

# Regex
Regex.compile!(pattern, "i")
|> Regex.match?(msgid)
```

---

## Testing Requirements

### Unit Tests
- [ ] Test substring matching (case-insensitive)
- [ ] Test regex matching
- [ ] Test case sensitivity in regex mode
- [ ] Test limit option
- [ ] Test empty results
- [ ] Test search_value with msgstr
- [ ] Test with multi-line entries

### Integration Tests
- [ ] Test Mix task with fixture file
- [ ] Test JSON output format
- [ ] Test with --locale flag
- [ ] Test with --limit flag
- [ ] Test error handling (locale not found)

---

## Acceptance Criteria

- [x] Both search commands work correctly
- [x] Substring and regex matching implemented
- [x] Limit option works
- [x] JSON and text output supported
- [x] Works with --locale flag
- [x] Helpful error messages
- [x] All tests passing (53 search-related tests)
- [x] Commands documented with @moduledoc and @shortdoc
- [x] Functions documented with @doc and @spec

---

## Progress Log

### 2025-10-15 - Starting Implementation
- Beginning work on task 005
- Dependencies completed: tasks 002 (Core Parsing), 003 (Config), 004 (Output Formatting)
- Will implement both `search` (msgid) and `search_value` (msgstr) operations
- Plan: Start with Search operation module, then tests, then Mix task, repeat for SearchValue

### 2025-10-15 - Implementation Complete

**Created Operation Modules:**
- `lib/gettext_ops/operations/search.ex` - Search by msgid (source text)
- `lib/gettext_ops/operations/search_value.ex` - Search by msgstr (translated text)

**Key Implementation Details:**
- Both operations support substring matching (case-insensitive by default)
- Both operations support regex matching with `--regex` flag
- Regex patterns are compiled with case-insensitive flag by default
- Substring patterns are converted to case-insensitive regex using `Regex.escape/1`
- Limit option properly restricts number of results
- Full locale validation and helpful error messages

**Created Mix Tasks:**
- `lib/mix/tasks/gettext_ops.search.ex` - CLI interface for searching msgid
- `lib/mix/tasks/gettext_ops.search_value.ex` - CLI interface for searching msgstr

**Mix Task Features:**
- Full OptionParser integration with short aliases (`-l`, `-d`, `-r`, `-n`, `-j`)
- JSON and text output modes (delegates to `GettextOps.Output` module)
- Comprehensive usage help text
- Proper error handling and validation

**Created Test Suites:**
- `test/gettext_ops/operations/search_test.exs` (15 unit tests)
- `test/gettext_ops/operations/search_value_test.exs` (16 unit tests)
- `test/mix/tasks/gettext_ops.search_test.exs` (11 integration tests)
- `test/mix/tasks/gettext_ops.search_value_test.exs` (11 integration tests)

**Test Coverage:**
- Substring and regex matching (case-insensitive)
- Limit option functionality
- JSON and text output formats
- Error handling (missing arguments, invalid locale)
- Short option aliases
- Domain specification
- Empty result sets

**Total Tests for Task 005:** 53 tests, all passing

**Acceptance Criteria:** All criteria met and verified through comprehensive test suite.

---

## Related Files

- `lib/gettext_ops/operations/search.ex`
- `lib/gettext_ops/operations/search_value.ex`
- `lib/mix/tasks/gettext_ops.search.ex`
- `lib/mix/tasks/gettext_ops.search_value.ex`
- `test/gettext_ops/operations/search_test.exs`
- `test/gettext_ops/operations/search_value_test.exs`
- `test/mix/tasks/gettext_ops.search_test.exs`

---

## References

- Elixir Regex: https://hexdocs.pm/elixir/Regex.html
- Mix.Task: https://hexdocs.pm/mix/Mix.Task.html
- OptionParser: https://hexdocs.pm/elixir/OptionParser.html
