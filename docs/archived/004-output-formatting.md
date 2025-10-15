# Task 004: Output Formatting

**Status:** `completed`
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

- [x] `GettextOps.Output` module
- [x] JSON formatting for messages
- [x] Plain text formatting (matches .po format)
- [x] Line-delimited JSON output support
- [x] Tests for both formats
- [x] Handle multi-line msgid/msgstr in output

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
- [x] Test plain text formatting for simple entry
- [x] Test plain text formatting for multi-line entry
- [x] Test JSON formatting
- [x] Test JSON with references
- [x] Test line-delimited JSON for multiple entries
- [x] Test escaping in JSON output
- [x] Test empty msgstr formatting

### Integration Tests
- [x] Parse fixture file and format back to text (round-trip)
- [x] Format multiple entries with both formats

---

## Acceptance Criteria

- [x] Plain text output matches .po file format
- [x] JSON output is valid and parseable
- [x] Line-delimited JSON works (not JSON array)
- [x] Multi-line entries formatted correctly
- [x] References included in JSON
- [x] All tests passing (149 total: 27 doctests + 122 unit tests)
- [x] Functions documented with @doc and @spec

---

## Progress Log

### 2025-10-15 - Starting Implementation
- Beginning work on task 004
- Task 002 (Core Parsing) is completed and archived
- Will implement output formatting for both plain text and JSON formats

### 2025-10-15 - Implementation Complete

**Created `lib/gettext_ops/output.ex`:**
- Implemented all core formatting functions as specified
- `format_text/1` - Plain text output matching .po format
- `format_json/1` - JSON output using Elixir 1.18+ built-in JSON module
- `to_map/1` - Converts Expo messages to maps for JSON encoding
- `print_message/2` and `print_messages/2` - Output functions supporting both formats
- Proper handling of both `Expo.Message.Singular` and `Expo.Message.Plural` types

**Key Implementation Details:**
- String escaping for plain text output (quotes, newlines, tabs, etc.)
- Multi-line msgid/msgstr support via `Entry.get_msgid/1` and `Entry.get_msgstr/1`
- References formatted as "file:line" strings in JSON
- Optional fields (references, comments, flags) only included when present
- Line-delimited JSON output (one object per line, not array)
- Plural message support for text format (msgid_plural, msgstr[0], msgstr[1], etc.)

**Created `test/gettext_ops/output_test.exs`:**
- Comprehensive test suite with 29 unit tests + 5 doctests (34 total for this module)
- Tests for simple and multi-line formatting
- Tests for special character escaping
- Tests for JSON with references, comments, and flags
- Tests for line-delimited JSON output
- Integration tests with fixture .po files
- Tests for both singular and plural messages

**Issue Resolved:**
- Fixed doctest failure due to JSON key ordering not being guaranteed
- Converted problematic doctest to comment-based example
- All 149 tests now passing (27 doctests + 122 unit tests across all modules)

**Acceptance Criteria Verification:**
- ✅ Plain text output matches .po file format
- ✅ JSON output is valid and parseable
- ✅ Line-delimited JSON works (not JSON array)
- ✅ Multi-line entries formatted correctly
- ✅ References included in JSON
- ✅ All tests passing
- ✅ Functions documented with @doc and @spec

**Task Status:** ✅ **COMPLETE** - All deliverables implemented, tested, and verified.

---

## Related Files

- `lib/gettext_ops/output.ex`
- `test/gettext_ops/output_test.exs`

---

## References

- Line-delimited JSON: http://jsonlines.org/
- Elixir JSON module: https://hexdocs.pm/elixir/1.18/JSON.html
- .po file format: https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
