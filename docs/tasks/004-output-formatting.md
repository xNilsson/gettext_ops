# Task 004: Output Formatting

**Status:** `not-started`
**Created:** 2025-10-15
**Depends On:** `002`

---

## Goal

Implement output formatting for both JSON and plain text formats to support LLM-friendly APIs and human-readable output.

---

## Context

All Mix tasks need to output results in two formats:
1. **Plain text** - Human-readable, matches .po format for entries
2. **JSON** - Line-delimited JSON for piping to LLMs and other tools

This module provides consistent formatting across all commands.

For reference, the originial `poflow` implementation in go can be found at: ~/code/poflow

---

## Deliverables

- [ ] `GettextOps.Output` module
- [ ] JSON formatting for messages
- [ ] Plain text formatting (matches .po format)
- [ ] Line-delimited JSON output support
- [ ] Tests for both formats
- [ ] Handle multi-line msgid/msgstr in output

---

## Implementation Notes

### Key Decisions
- Use line-delimited JSON (one object per line), not JSON arrays
- Plain text output matches .po file format
- Include references in JSON output
- Keep output simple and parseable

### Output Format Examples

**Plain text:**
```
msgid "Sign In"
msgstr ""

msgid "Welcome"
msgstr "Välkommen"
```

**JSON (line-delimited):**
```json
{"msgid":"Sign In","msgstr":"","references":["lib/auth.ex:12"]}
{"msgid":"Welcome","msgstr":"Välkommen","references":["lib/home.ex:5"]}
```

### API Design
```elixir
defmodule GettextOps.Output do
  @doc "Format a message as plain text (.po format)"
  @spec format_text(Expo.Message.t()) :: String.t()
  def format_text(message)

  @doc "Format a message as JSON"
  @spec format_json(Expo.Message.t()) :: String.t()
  def format_json(message)

  @doc "Print a message to stdout in specified format"
  @spec print_message(Expo.Message.t(), :text | :json) :: :ok
  def print_message(message, format)

  @doc "Print multiple messages with separator"
  @spec print_messages([Expo.Message.t()], :text | :json) :: :ok
  def print_messages(messages, format)

  @doc "Convert message to map for JSON encoding"
  @spec to_map(Expo.Message.t()) :: map()
  def to_map(message)
end
```

### Handling Multi-line Strings

Expo stores msgid/msgstr as lists of strings. We need to join them:
```elixir
# Expo.Message:
%{msgid: ["Line 1", "Line 2"]}

# Output:
msgid: "Line 1\nLine 2"
```

### JSON Schema
```elixir
%{
  msgid: "string",
  msgstr: "string",
  references: ["file:line", ...],  # Optional
  comments: ["comment", ...],       # Optional (if needed)
  flags: ["fuzzy"]                  # Optional (if needed)
}
```

---

## Testing Requirements

### Unit Tests
- [ ] Test plain text formatting for simple entry
- [ ] Test plain text formatting for multi-line entry
- [ ] Test JSON formatting
- [ ] Test JSON with references
- [ ] Test line-delimited JSON for multiple entries
- [ ] Test escaping in JSON output
- [ ] Test empty msgstr formatting

### Integration Tests
- [ ] Parse fixture file and format back to text (round-trip)
- [ ] Format multiple entries with both formats

---

## Acceptance Criteria

- [ ] Plain text output matches .po file format
- [ ] JSON output is valid and parseable
- [ ] Line-delimited JSON works (not JSON array)
- [ ] Multi-line entries formatted correctly
- [ ] References included in JSON
- [ ] All tests passing
- [ ] Functions documented with @doc and @spec

---

## Progress Log

_Updates will be added here as work progresses_

---

## Related Files

- `lib/gettext_ops/output.ex`
- `test/gettext_ops/output_test.exs`

---

## References

- Line-delimited JSON: http://jsonlines.org/
- Elixir JSON module: https://hexdocs.pm/elixir/1.18/JSON.html
- .po file format: https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
