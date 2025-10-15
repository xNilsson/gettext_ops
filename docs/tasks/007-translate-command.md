# Task 007: Translate Command

**Status:** `not-started`
**Created:** 2025-10-15
**Depends On:** `002, 003, 004`
**Can Be Parallelized:** Yes (parallel with 005, 006, 008)

---

## Goal

Implement the translate command to update msgstr (translations) in .po files from stdin, file, or inline input.

---

## Context

This is the **most important command** for the workflow. It enables bulk translation updates without manually editing .po files. Accepts input in format: `msgid = msgstr` (one per line).

Critical features:
- Accept input from stdin (heredoc), file, or inline
- Update .po files in-place atomically
- Preserve comments, references, and formatting
- Report what was updated and what wasn't found

---

## Deliverables

- [ ] `GettextOps.Operations.Translate` module
- [ ] `mix gettext_ops.translate` task
- [ ] Parse translation input format
- [ ] Update .po files atomically
- [ ] Support stdin, file, and inline input
- [ ] Force flag for partial updates
- [ ] Detailed update summary
- [ ] Tests for all input methods

---

## Implementation Notes

### Key Decisions
- Input format: `msgid = msgstr` (one per line)
- Skip empty lines and comments starting with `#`
- Atomic updates: write to temp file, then rename
- Fail if any msgid not found (unless `--force` flag)
- Preserve all Expo message metadata

### Input Format
```
Sign In = Logga in
Sign Out = Logga ut
Welcome = Välkommen
Error: Invalid input = Fel: Ogiltig inmatning
```

### API Design

**Operation module:**
```elixir
defmodule GettextOps.Operations.Translate do
  @doc "Parse translation input (msgid = msgstr format)"
  @spec parse_translations(String.t()) ::
    {:ok, %{String.t() => String.t()}} | {:error, term()}
  def parse_translations(input)

  @doc "Apply translations to a .po file"
  @spec run(String.t(), keyword()) ::
    {:ok, %{updated: integer(), not_found: [String.t()]}} | {:error, term()}
  def run(input, opts)

  # opts: [locale: "sv", domain: "default", force: false]
end
```

**Mix task:**
```elixir
defmodule Mix.Tasks.GettextOps.Translate do
  use Mix.Task

  @shortdoc "Apply translations from stdin or file"

  @moduledoc """
  Update msgstr (translations) in .po files.

  ## Usage

      # From stdin (heredoc)
      mix gettext_ops.translate --locale sv <<EOF
      Sign In = Logga in
      Sign Out = Logga ut
      EOF

      # From file
      mix gettext_ops.translate --locale sv --file translations.txt

      # From pipe
      echo "Welcome = Välkommen" | mix gettext_ops.translate --locale sv

  ## Input Format

  Each line should be: msgid = msgstr

      Sign In = Logga in
      Sign Out = Logga ut
      Welcome = Välkommen

  ## Options

    * `--locale` / `-l` - Target locale (required)
    * `--domain` / `-d` - Gettext domain (default: "default")
    * `--file` / `-f` - Input file (uses stdin if not provided)
    * `--force` - Continue even if msgid not found (show warnings)
  """

  def run(args)
end
```

### CLI Usage Examples
```bash
# From stdin (heredoc) - most common
mix gettext_ops.translate --locale sv <<EOF
Sign In = Logga in
Sign Out = Logga ut
Welcome = Välkommen
EOF

# From file
mix gettext_ops.translate --locale sv --file translations.txt

# From pipe
echo "Welcome = Välkommen" | mix gettext_ops.translate --locale sv

# With force flag (ignore missing msgids)
mix gettext_ops.translate --locale sv --force --file partial.txt

# LLM workflow
mix gettext_ops.list_untranslated --locale sv --json --limit 10 | \
  llm "translate to Swedish" | \
  mix gettext_ops.translate --locale sv
```

### Translation Parsing
```elixir
def parse_translations(input) do
  lines = String.split(input, "\n", trim: true)

  translations =
    lines
    |> Enum.reject(&(String.starts_with?(&1, "#") or String.trim(&1) == ""))
    |> Enum.map(&parse_line/1)
    |> Enum.reject(&is_nil/1)
    |> Map.new()

  {:ok, translations}
end

defp parse_line(line) do
  case String.split(line, "=", parts: 2) do
    [msgid, msgstr] ->
      {String.trim(msgid), String.trim(msgstr)}
    _ ->
      nil  # Invalid line
  end
end
```

### Atomic Update Process
```elixir
1. Parse .po file with Expo
2. Map translations by msgid
3. Update matching messages
4. Write to temporary file
5. Rename temp file to original (atomic)
6. Return summary
```

---

## Testing Requirements

### Unit Tests
- [ ] Test parsing valid translation input
- [ ] Test parsing with empty lines
- [ ] Test parsing with comments
- [ ] Test parsing invalid lines
- [ ] Test updating single entry
- [ ] Test updating multiple entries
- [ ] Test msgid not found (error)
- [ ] Test --force flag (ignore not found)
- [ ] Test preserving comments and references
- [ ] Test multi-line msgstr updates

### Integration Tests
- [ ] Test stdin input with heredoc
- [ ] Test file input
- [ ] Test pipe input
- [ ] Test atomic update (file not corrupted on error)
- [ ] Test update summary output

---

## Acceptance Criteria

- [ ] Parses translation input correctly
- [ ] Updates .po files atomically
- [ ] Accepts stdin, file input
- [ ] Force flag works
- [ ] Detailed summary printed
- [ ] Error messages helpful
- [ ] Preserves all message metadata
- [ ] All tests passing
- [ ] Command documented with @moduledoc and @shortdoc
- [ ] Functions documented with @doc and @spec

---

## Progress Log

_Updates will be added here as work progresses_

---

## Related Files

- `lib/gettext_ops/operations/translate.ex`
- `lib/mix/tasks/gettext_ops.translate.ex`
- `test/gettext_ops/operations/translate_test.exs`
- `test/mix/tasks/gettext_ops.translate_test.exs`

---

## References

- Example from readme-new.md lines 260-302
- Expo.PO.compose: https://hexdocs.pm/expo/Expo.PO.html#compose/1
- File.rename!/2 for atomic updates: https://hexdocs.pm/elixir/File.html#rename/2
