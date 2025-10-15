# Task 006: List Untranslated Command

**Status:** `not-started`
**Created:** 2025-10-15
**Depends On:** `002, 003, 004`
**Can Be Parallelized:** Yes (parallel with 005, 007, 008)

---

## Goal

Implement functionality to list all entries with empty translations (untranslated entries) with limit and JSON output support.

---

## Context

This is the most frequently used command for developers and LLMs. It shows what needs translation without loading entire .po files. Critical for token efficiency with AI agents.

**Token savings example:** Instead of reading a 5000-line .po file (~15k tokens), get exactly the 10 untranslated entries needed (~500 tokens).

For reference, the originial `poflow` implementation in go can be found at: ~/code/poflow

---

## Deliverables

- [ ] `GettextOps.Operations.ListUntranslated` module
- [ ] `mix gettext_ops.list_untranslated` task
- [ ] Support for limit option
- [ ] JSON and text output
- [ ] Locale-specific listing
- [ ] Domain support
- [ ] Tests for various scenarios

---

## Implementation Notes

### Key Decisions
- An entry is "untranslated" if msgstr is empty (`[""]` or `[]`)
- Support `--limit` to cap results (important for LLMs)
- Support `--domain` for non-default domains
- Default to text output, `--json` for JSON

### API Design

**Operation module:**
```elixir
defmodule GettextOps.Operations.ListUntranslated do
  @doc "List all untranslated entries"
  @spec run(keyword()) ::
    {:ok, [Expo.Message.t()]} | {:error, term()}
  def run(opts)

  # opts: [locale: "sv", domain: "default", limit: nil, json: false]
end
```

**Mix task:**
```elixir
defmodule Mix.Tasks.GettextOps.ListUntranslated do
  use Mix.Task

  @shortdoc "List untranslated entries (empty msgstr)"

  @moduledoc """
  List all entries with empty translations.

  ## Usage

      mix gettext_ops.list_untranslated --locale sv
      mix gettext_ops.list_untranslated --locale sv --json --limit 10

  ## Options

    * `--locale` / `-l` - Target locale (e.g., sv, en, de)
    * `--domain` / `-d` - Gettext domain (default: "default")
    * `--json` - Output as line-delimited JSON
    * `--limit` / `-n` - Limit number of results
  """

  def run(args)
end
```

### CLI Usage Examples
```bash
# List all untranslated Swedish entries
mix gettext_ops.list_untranslated --locale sv

# Get first 10 as JSON (perfect for LLMs)
mix gettext_ops.list_untranslated --locale sv --json --limit 10

# Count untranslated entries
mix gettext_ops.list_untranslated --locale sv | grep "msgid" | wc -l

# Save to file for translation
mix gettext_ops.list_untranslated --locale sv --json --limit 20 > to_translate.json
```

### Untranslated Check
```elixir
# An entry is untranslated if:
defp untranslated?(%Expo.Message{msgstr: []}), do: true
defp untranslated?(%Expo.Message{msgstr: [""]}), do: true
defp untranslated?(%Expo.Message{msgstr: msgstr}) when is_list(msgstr) do
  Enum.all?(msgstr, &(&1 == ""))
end
defp untranslated?(_), do: false
```

---

## Testing Requirements

### Unit Tests
- [ ] Test listing all untranslated entries
- [ ] Test with limit option
- [ ] Test with no untranslated entries (empty result)
- [ ] Test with all entries untranslated
- [ ] Test JSON output format
- [ ] Test domain option
- [ ] Test error handling (locale not found)

### Integration Tests
- [ ] Test Mix task with fixture files
- [ ] Test piping output to other commands
- [ ] Test with --json flag
- [ ] Test with various limits

### Test Fixtures
- Use `test/fixtures/empty.po` with untranslated entries
- Use `test/fixtures/test.po` with mixed translated/untranslated

---

## Acceptance Criteria

- [ ] Command lists only untranslated entries
- [ ] Limit option works correctly
- [ ] JSON and text output supported
- [ ] Works with --locale and --domain flags
- [ ] Helpful error messages
- [ ] All tests passing
- [ ] Command documented with @moduledoc and @shortdoc
- [ ] Functions documented with @doc and @spec

---

## Progress Log

_Updates will be added here as work progresses_

---

## Related Files

- `lib/gettext_ops/operations/list_untranslated.ex`
- `lib/mix/tasks/gettext_ops.list_untranslated.ex`
- `test/gettext_ops/operations/list_untranslated_test.exs`
- `test/mix/tasks/gettext_ops.list_untranslated_test.exs`

---

## References

- Example from readme-new.md lines 176-212
- Phoenix Gettext: https://hexdocs.pm/gettext/Gettext.html
