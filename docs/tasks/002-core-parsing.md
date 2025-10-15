# Task 002: Core Parsing with Expo

**Status:** `not-started`
**Created:** 2025-10-15
**Depends On:** `001`

---

## Goal

Build the core parsing functionality using the Expo library to read and manipulate .po file entries with proper streaming support.

---

## Context

This task establishes the foundation for all other operations. We use Expo (the same library Phoenix Gettext uses) to parse .po files. Unlike the Go version which had a custom streaming parser, we leverage Expo's battle-tested implementation. We need helper functions for common operations like filtering empty entries and searching.

**Important:** We use Expo's API, not a custom parser!

---

## Deliverables

- [ ] `GettextOps.Entry` module with helper functions
- [ ] `GettextOps.Parser` module wrapping Expo
- [ ] `GettextOps.Writer` module for updating .po files
- [ ] Unit tests for parsing various .po formats
- [ ] Tests for multi-line entries and escape sequences

---

## Implementation Notes

### Key Decisions
- Use `Expo.PO.parse_file/1` for reading .po files
- Use `Expo.PO.compose/1` for writing .po files
- Keep `Expo.Message` as the primary data structure (don't create custom structs)
- Add helper predicates like `empty?/1` for common filters

### API Design
```elixir
# GettextOps.Parser module
defmodule GettextOps.Parser do
  @doc "Parse a .po file and return messages"
  @spec parse_file(String.t()) :: {:ok, [Expo.Message.t()]} | {:error, term()}
  def parse_file(path)

  @doc "Parse .po file and filter messages"
  @spec parse_and_filter(String.t(), (Expo.Message.t() -> boolean())) ::
    {:ok, [Expo.Message.t()]} | {:error, term()}
  def parse_and_filter(path, filter_fn)
end

# GettextOps.Entry module (helpers)
defmodule GettextOps.Entry do
  @doc "Check if a message has empty msgstr (untranslated)"
  @spec untranslated?(Expo.Message.t()) :: boolean()
  def untranslated?(message)

  @doc "Get msgid as string from message"
  @spec get_msgid(Expo.Message.t()) :: String.t()
  def get_msgid(message)

  @doc "Get msgstr as string from message"
  @spec get_msgstr(Expo.Message.t()) :: String.t()
  def get_msgstr(message)

  @doc "Check if msgid matches pattern"
  @spec matches_msgid?(Expo.Message.t(), String.t() | Regex.t()) :: boolean()
  def matches_msgid?(message, pattern)
end

# GettextOps.Writer module
defmodule GettextOps.Writer do
  @doc "Update messages in a .po file"
  @spec update_file(String.t(), (Expo.Message.t() -> Expo.Message.t())) ::
    :ok | {:error, term()}
  def update_file(path, update_fn)

  @doc "Update specific messages by msgid"
  @spec update_translations(String.t(), %{String.t() => String.t()}) ::
    {:ok, %{updated: integer()}} | {:error, term()}
  def update_translations(path, translations)
end
```

### Expo Message Structure
```elixir
%Expo.Message{
  msgid: ["Welcome"],      # List of strings (handles multi-line)
  msgstr: ["Välkommen"],   # List of strings
  msgctxt: nil,            # Context (optional)
  comments: [],            # Comments
  flags: [],               # Flags like "fuzzy"
  references: []           # Source code references
}
```

---

## Testing Requirements

### Unit Tests
- [ ] Test parsing simple .po file
- [ ] Test parsing multi-line msgid/msgstr
- [ ] Test `untranslated?/1` predicate
- [ ] Test `matches_msgid?/2` with string and regex
- [ ] Test updating translations in file
- [ ] Test preserving comments and references
- [ ] Test handling empty .po files

### Integration Tests
- [ ] Parse all fixture files successfully
- [ ] Round-trip: parse → update → parse (verify no corruption)

### Test Fixtures
Use fixtures from task 001:
- `test/fixtures/test.po` - Basic entries
- `test/fixtures/empty.po` - Untranslated entries
- `test/fixtures/multiline.po` - Multi-line entries

---

## Acceptance Criteria

- [ ] Can parse .po files using Expo
- [ ] Can filter untranslated entries
- [ ] Can search entries by msgid/msgstr
- [ ] Can update translations and write back to file
- [ ] All tests passing
- [ ] Functions documented with @doc and @spec
- [ ] No custom parsing logic (all via Expo)

---

## Progress Log

_Updates will be added here as work progresses_

---

## Related Files

- `lib/gettext_ops/parser.ex`
- `lib/gettext_ops/entry.ex`
- `lib/gettext_ops/writer.ex`
- `test/gettext_ops/parser_test.exs`
- `test/gettext_ops/entry_test.exs`
- `test/gettext_ops/writer_test.exs`

---

## References

- Expo documentation: http://hex2txt.fly.dev/expo/llms.txt 
- Expo.PO module: https://hexdocs.pm/expo/Expo.PO.html
- Expo.Message struct: https://hexdocs.pm/expo/Expo.Message.html
