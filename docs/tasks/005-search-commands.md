# Task 005: Search Commands

**Status:** `not-started`
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

---

## Deliverables

- [ ] `GettextOps.Operations.Search` module
- [ ] `GettextOps.Operations.SearchValue` module
- [ ] `mix gettext_ops.search` task
- [ ] `mix gettext_ops.search_value` task
- [ ] Support for regex and substring matching
- [ ] JSON and text output
- [ ] Limit option
- [ ] Tests for both search types

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

- [ ] Both search commands work correctly
- [ ] Substring and regex matching implemented
- [ ] Limit option works
- [ ] JSON and text output supported
- [ ] Works with --locale flag
- [ ] Helpful error messages
- [ ] All tests passing
- [ ] Commands documented with @moduledoc and @shortdoc
- [ ] Functions documented with @doc and @spec

---

## Progress Log

_Updates will be added here as work progresses_

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
