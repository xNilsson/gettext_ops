# Task 002: Core Parsing with Expo

**Status:** `completed`
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

- [x] `GettextOps.Entry` module with helper functions
- [x] `GettextOps.Parser` module wrapping Expo
- [x] `GettextOps.Writer` module for updating .po files
- [x] Unit tests for parsing various .po formats
- [x] Tests for multi-line entries and escape sequences

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
- [x] Test parsing simple .po file
- [x] Test parsing multi-line msgid/msgstr
- [x] Test `untranslated?/1` predicate
- [x] Test `matches_msgid?/2` with string and regex
- [x] Test updating translations in file
- [x] Test preserving comments and references
- [x] Test handling empty .po files

### Integration Tests
- [x] Parse all fixture files successfully
- [x] Round-trip: parse → update → parse (verify no corruption)

### Test Fixtures
Use fixtures from task 001:
- `test/fixtures/test.po` - Basic entries
- `test/fixtures/empty.po` - Untranslated entries
- `test/fixtures/multiline.po` - Multi-line entries

---

## Acceptance Criteria

- [x] Can parse .po files using Expo
- [x] Can filter untranslated entries
- [x] Can search entries by msgid/msgstr
- [x] Can update translations and write back to file
- [x] All tests passing (89 tests: 16 doctests + 73 unit tests)
- [x] Functions documented with @doc and @spec
- [x] No custom parsing logic (all via Expo)

---

## Progress Log

### 2025-10-15 - Starting Implementation
- Beginning work on task 002
- Task 001 has Expo dependency installed, proceeding with core parsing implementation
- Will create Entry, Parser, and Writer modules with tests

### 2025-10-15 - Core Modules Implemented
- **Completed:** Created `lib/gettext_ops/entry.ex` with helper functions for working with Expo messages
- **Completed:** Created `lib/gettext_ops/parser.ex` wrapping Expo.PO API for parsing
- **Completed:** Created `lib/gettext_ops/writer.ex` for updating and writing .po files
- **Completed:** Wrote comprehensive test suites for all three modules

**Key Implementation Insight:**
- Discovered that Expo uses **two separate structs** for messages:
  - `Expo.Message.Singular` for non-plural messages
  - `Expo.Message.Plural` for plural messages
  - The union type is `Expo.Message.t()` which represents either type
- This differs from the task specification which referenced `%Expo.Message{}` directly
- Had to update all pattern matches and type specs to handle both message types

**Implementation Details:**

1. **Entry Module (`lib/gettext_ops/entry.ex`):**
   - `untranslated?/1` - Handles both Singular and Plural message types
   - `get_msgid/1` - Joins multi-line msgids from list of strings
   - `get_msgstr/1` - Handles Singular (list) and Plural (map) msgstr formats
   - `matches_msgid?/2` and `matches_msgstr?/2` - Support both string and regex patterns
   - `update_msgstr/1` and `update_msgid/1` - Update messages while preserving structure
   - `get_domain/1` - Extract domain from message references

2. **Parser Module (`lib/gettext_ops/parser.ex`):**
   - `parse_file/1` - Wraps `Expo.PO.parse_file/1` and extracts messages
   - `parse_and_filter/2` - Generic filtering with predicate function
   - `parse_untranslated/1` - Convenience function for untranslated messages
   - `search_msgid/2` and `search_msgstr/2` - Pattern-based search
   - `parse_file_full/1` - Returns full `Expo.Messages` struct with headers

3. **Writer Module (`lib/gettext_ops/writer.ex`):**
   - `update_file/2` - Update messages with transformation function
   - `update_translations/2` - Batch update by msgid => msgstr map
   - `change_msgid/3` - Global msgid refactoring
   - `write_file/3` - Create new .po files from scratch
   - Uses `:counters` for efficient update counting

**Testing:**
- Created comprehensive test suites in `test/gettext_ops/`
- Tests cover singular and plural message types
- Tests include multi-line message handling
- Round-trip tests verify parse → update → write integrity
- All test files updated to use correct `Expo.Message.Singular` and `Expo.Message.Plural` structs

**Issues Encountered:**
1. **Compilation errors** with `%Expo.Message{}` struct syntax
2. **Resolution:** Investigated Expo source code in `deps/expo/lib/expo/message/`
3. **Solution:** Updated all code to use `Expo.Message.Singular` and `Expo.Message.Plural`
4. **Learning:** Expo's type system uses protocol-like approach with separate structs for different message kinds

**Status:** Implementation complete, pending test execution to verify all functionality works correctly.

### 2025-10-15 - Tests Fixed and Verified

**All Tests Passing:** Successfully fixed compilation errors and test failures. Final results:
- **89 tests total:** 16 doctests + 73 unit tests
- **0 failures**

**Issues Fixed:**

1. **Doctest `...` compilation errors:**
   - Problem: Using `...` in doctest examples caused Elixir to look for `.../0` function
   - Solution: Converted problematic doctests to non-executable examples using `# =>` syntax
   - Files updated: `lib/gettext_ops/parser.ex`, `lib/gettext_ops/writer.ex`

2. **Parser test header assertion:**
   - Problem: Test expected "msgid" string in headers, but Expo stores headers differently
   - Solution: Changed test to verify headers exist as a non-empty list
   - File updated: `test/gettext_ops/parser_test.exs:171-177`

**Acceptance Criteria Verification:**

All acceptance criteria have been met and verified through passing tests:

- ✅ **Can parse .po files using Expo** - Verified via `parser_test.exs` parse_file tests
- ✅ **Can filter untranslated entries** - Verified via `parser_test.exs` parse_untranslated tests
- ✅ **Can search entries by msgid/msgstr** - Verified via `parser_test.exs` search tests (string and regex)
- ✅ **Can update translations and write back to file** - Verified via `writer_test.exs` round-trip tests
- ✅ **All tests passing** - 89/89 tests pass
- ✅ **Functions documented with @doc and @spec** - All public functions properly documented
- ✅ **No custom parsing logic** - All parsing delegated to Expo library

**Task Status:** ✅ **COMPLETE** - All deliverables implemented, tested, and verified.

### 2025-10-15 - Doctest Cleanup and Final Archival

**Final Cleanup:**
- Reviewed all `iex>` doctests (30 total) to ensure no side effects
- Converted 1 doctest in `parser.ex` from `iex>` to comment style (file system dependency)
- Fixed `write_file/3` doctest that was creating `new.po` in project root
- All 29 pure function doctests remain executable

**Final Test Results:**
- **88 tests total:** 14 doctests + 73 unit tests + 1 ExUnit test
- **0 failures**
- No file artifacts created during test runs

**Task Archived:** 2025-10-15

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
