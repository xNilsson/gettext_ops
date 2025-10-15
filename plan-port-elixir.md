# Poflow Elixir Port - Project Plan

**Status:** Planning
**Created:** 2025-10-15
**Goal:** Port poflow from Go to Elixir as a Hex package with Mix tasks and optional MCP server

---

## Context & Motivation

### Why Port to Elixir?

1. **Better Phoenix Integration**: Native Elixir library integrates seamlessly with Phoenix projects
2. **Programmatic API**: Can call functions directly from Elixir code without shelling out
3. **Simpler Workflow**: No file-based translation input needed - pass multiline strings directly
4. **Config Integration**: Use Phoenix config system (`config.exs`) instead of separate YAML files
5. **LLM-Friendly**: Mix tasks work well with stdin/stdout, MCP server enables tool integration

### Current Go Implementation Stats

- **Size**: ~2,700 lines of Go code across 19 files
- **Commands**: `search`, `searchvalue`, `listempty`, `translate`, `edit`, `version`
- **Architecture**: Streaming line-by-line parser (no in-memory AST)
- **Dependencies**: Cobra (CLI), Viper (config), standard library
- **Key Features**:
  - Fast streaming parser for large .po files
  - JSON output support for all commands
  - Config-based path resolution (`gettext_path`)
  - In-place file updates (translate/edit)
  - Source code updates (edit command)

### Design Decisions for Elixir Port

**What Changes:**
- ❌ No CLI binary → ✅ Mix tasks
- ❌ No YAML config files → ✅ Phoenix `config.exs`
- ❌ File-based translation input → ✅ Direct string/stdin input
- ❌ Cobra/Viper → ✅ `OptionParser` + Elixir `Config`

**What Stays the Same:**
- ✅ Streaming line-by-line parser (using Elixir `Stream`)
- ✅ JSON output support
- ✅ Stdin/stdout/file I/O patterns
- ✅ Same command structure and flags
- ✅ Config-based path resolution

---

## Architecture Overview

### Package Structure

```
poflow/
├── lib/
│   ├── poflow.ex                  # Main API module
│   ├── poflow/
│   │   ├── parser.ex              # Streaming .po file parser
│   │   ├── entry.ex               # MsgEntry struct
│   │   ├── config.ex              # Config handling
│   │   ├── output.ex              # JSON/text formatting
│   │   ├── translate.ex           # Translation merge logic
│   │   ├── search.ex              # Search by msgid
│   │   ├── search_value.ex        # Search by msgstr
│   │   └── editor.ex              # Edit msgid across files
│   └── mix/
│       └── tasks/
│           ├── poflow.search.ex
│           ├── poflow.searchvalue.ex
│           ├── poflow.listempty.ex
│           ├── poflow.translate.ex
│           └── poflow.edit.ex
├── test/
│   ├── poflow/
│   │   ├── parser_test.exs
│   │   ├── translate_test.exs
│   │   ├── search_test.exs
│   │   └── editor_test.exs
│   └── test_helper.exs
├── mix.exs
├── README.md
└── CHANGELOG.md
```

### Core Modules

#### `Poflow` (Public API)
```elixir
Poflow.search(pattern, opts)
Poflow.search_value(pattern, opts)
Poflow.list_empty(opts)
Poflow.translate(translations, opts)
Poflow.edit(old_msgid, new_msgid, opts)
```

#### `Poflow.Parser` (Streaming Parser)
```elixir
# Stream entries from a file
Poflow.Parser.stream(file_path)
|> Stream.filter(&Poflow.Entry.empty?/1)
|> Enum.take(10)
```

#### `Poflow.Entry` (Data Structure)
```elixir
%Poflow.Entry{
  msgid: "Welcome",
  msgstr: "Välkommen",
  comments: ["translator note"],
  references: ["lib/my_app_web/live/home_live.ex:15"],
  raw_lines: [...]  # Original lines for preservation
}
```

---

## Implementation Plan

### Phase 1: Core Parsing & Data Structures

**Goal:** Implement the streaming .po file parser and entry data structure

#### Tasks

**1.1 Project Setup**
- [ ] Create new Elixir project: `mix new poflow`
- [ ] Configure `mix.exs` with dependencies (JSON support built-in to Elixir 1.18+)
- [ ] Add hex metadata (description, package, licenses)
- [ ] Create basic project structure (directories)
- [ ] Initialize git repository (if separate from Go version)

**1.2 Entry Module** (`lib/poflow/entry.ex`)
- [ ] Define `%Poflow.Entry{}` struct with `@derive {JSON.Encoder, only: [...]}`
- [ ] Implement `empty?/1` predicate
- [ ] Add type specs with `@type` and `@spec`
- [ ] Write doctests in module documentation

**1.3 Parser Module** (`lib/poflow/parser.ex`)
- [ ] Implement `stream/1` function (file path → Stream of entries)
- [ ] Port line-by-line parsing logic:
  - [ ] Handle comments (`#`, `#:` reference comments)
  - [ ] Parse `msgid` lines (single and multi-line)
  - [ ] Parse `msgstr` lines (single and multi-line)
  - [ ] Handle continuation lines (quoted strings)
  - [ ] Store `raw_lines` for later reconstruction
- [ ] Implement `unquote/1` helper (handle escape sequences: `\n`, `\t`, `\"`, `\\`)
- [ ] Implement `parse_all/1` convenience function (for testing)
- [ ] Capture file header (comments before first entry)

**1.4 Parser Tests** (`test/poflow/parser_test.exs`)
- [ ] Test empty file
- [ ] Test single entry
- [ ] Test multi-line msgid/msgstr
- [ ] Test entries with comments and references
- [ ] Test escape sequences (`\n`, `\t`, `\"`, `\\`)
- [ ] Test malformed entries (error handling)
- [ ] Test large file (performance/streaming)

**Deliverable:** Working parser that can stream .po file entries

---

### Phase 2: Config & Path Resolution

**Goal:** Replace Viper config with Elixir Config system

#### Tasks

**2.1 Config Module** (`lib/poflow/config.ex`)
- [ ] Define `config :poflow, gettext_path: "priv/gettext"`
- [ ] Implement `get_gettext_path/0` (reads from Application config)
- [ ] Implement `resolve_po_path/1` (language → full path)
  - Format: `{gettext_path}/{lang}/LC_MESSAGES/default.po`
- [ ] Implement `resolve_pot_path/0` (template file path)
  - Format: `{gettext_path}/default.pot`
- [ ] Implement `list_po_files/0` (find all .po files recursively)
- [ ] Implement `get_pot_file/0` (find .pot file if exists)

**2.2 Config Tests** (`test/poflow/config_test.exs`)
- [ ] Test path resolution for different languages
- [ ] Test missing config (error handling)
- [ ] Test `list_po_files/0` with fixture directory
- [ ] Test .pot file detection

**2.3 Documentation**
- [ ] Add config example to README
- [ ] Document how to set up in Phoenix projects

**Deliverable:** Config system that resolves .po file paths

---

### Phase 3: Output Formatting

**Goal:** Implement JSON and .po text output formatters

#### Tasks

**3.1 Output Module** (`lib/poflow/output.ex`)
- [ ] Implement `format_entry/2` (entry, :json | :text)
- [ ] Implement `output_entry/2` (print to stdout)
- [ ] Implement `format_po_text/1` (entry → .po format string)
  - [ ] Use `raw_lines` when available (preserves original formatting)
  - [ ] Reconstruct from fields when `raw_lines` missing
  - [ ] Handle multi-line msgid/msgstr
  - [ ] Escape special characters (`\n`, `\t`, `\"`, `\\`)
- [ ] Implement `escape_string/1` helper
- [ ] Implement `format_json/1` (entry → JSON line)

**3.2 Output Tests** (`test/poflow/output_test.exs`)
- [ ] Test JSON formatting (compare against expected JSON)
- [ ] Test .po text formatting (compare against original)
- [ ] Test escape sequences in output
- [ ] Test multi-line entries
- [ ] Test round-trip: parse → format → parse

**Deliverable:** Output formatters for JSON and .po text

---

### Phase 4: Search Commands

**Goal:** Implement search and searchvalue functionality

#### Tasks

**4.1 Search Module** (`lib/poflow/search.ex`)
- [ ] Implement `run/2` (pattern, opts)
- [ ] Handle options: `:regex`, `:limit`, `:language`, `:file`
- [ ] Implement substring matching (case-insensitive)
- [ ] Implement regex matching (using `Regex.compile!/1`)
- [ ] Filter entries by msgid match
- [ ] Support stdin, file path, or language config
- [ ] Format output (JSON or text)

**4.2 Search Value Module** (`lib/poflow/search_value.ex`)
- [ ] Implement `run/2` (pattern, opts)
- [ ] Same as search but filter by msgstr instead of msgid
- [ ] Reuse matching logic from search module

**4.3 Mix Task: search** (`lib/mix/tasks/poflow.search.ex`)
- [ ] Define Mix task with `@shortdoc`
- [ ] Parse arguments with `OptionParser`
  - Switches: `--re`, `--limit`, `--language`, `--json`
- [ ] Handle stdin vs file vs language input
- [ ] Call `Poflow.Search.run/2`
- [ ] Handle errors gracefully

**4.4 Mix Task: searchvalue** (`lib/mix/tasks/poflow.searchvalue.ex`)
- [ ] Define Mix task with `@shortdoc`
- [ ] Same structure as search task
- [ ] Call `Poflow.SearchValue.run/2`

**4.5 Search Tests** (`test/poflow/search_test.exs`)
- [ ] Test substring matching (case-insensitive)
- [ ] Test regex matching
- [ ] Test limit flag
- [ ] Test empty results
- [ ] Test JSON output format

**4.6 Integration Tests**
- [ ] Test Mix task with fixture .po file
- [ ] Test stdin input: `cat file.po | mix poflow.search "pattern"`
- [ ] Test language flag: `mix poflow.search "pattern" --language sv`

**Deliverable:** Working search and searchvalue commands

---

### Phase 5: List Empty Command

**Goal:** Implement listempty functionality

#### Tasks

**5.1 List Empty Logic** (in `Poflow` module)
- [ ] Implement `list_empty/1` function
- [ ] Filter entries where `Entry.empty?/1` is true
- [ ] Handle `:limit`, `:language`, `:file` options
- [ ] Format output (JSON or text)

**5.2 Mix Task: listempty** (`lib/mix/tasks/poflow.listempty.ex`)
- [ ] Define Mix task with `@shortdoc`
- [ ] Parse arguments: `--limit`, `--language`, `--json`
- [ ] Call `Poflow.list_empty/1`
- [ ] Handle stdin vs file vs language input

**5.3 Tests** (`test/poflow/list_empty_test.exs`)
- [ ] Test filtering empty entries
- [ ] Test limit flag
- [ ] Test with all entries empty
- [ ] Test with no empty entries

**Deliverable:** Working listempty command

---

### Phase 6: Translate Command

**Goal:** Implement translation merging (most important command!)

#### Tasks

**6.1 Translate Module** (`lib/poflow/translate.ex`)
- [ ] Implement `parse_translations/1` (multiline string → map)
  - Format: `msgid = msgstr` (one per line)
  - [ ] Skip empty lines and comments (`#`)
  - [ ] Parse and trim msgid/msgstr
  - [ ] Validate format (error on invalid lines)
- [ ] Implement `run/2` (translations, opts)
  - [ ] Parse .po file with Parser
  - [ ] Look up each entry's msgid in translations map
  - [ ] Update msgstr if found
  - [ ] Track updated entries and not-found msgids
  - [ ] Write to temp file, then rename (atomic update)
  - [ ] Write file header before entries
- [ ] Handle `:force` flag (continue if msgids not found)
- [ ] Handle `:stdout` flag (output to stdout instead of in-place)
- [ ] Handle `:language` option (resolve path from config)
- [ ] Print summary: updated count, not-found list

**6.2 Mix Task: translate** (`lib/mix/tasks/poflow.translate.ex`)
- [ ] Define Mix task with `@shortdoc` and `@moduledoc`
- [ ] Parse arguments:
  - `--language`, `--file`, `--force`, `--stdout`, `--json`, `--inline`
- [ ] Handle translation input sources:
  - [ ] From stdin (default, supports heredoc)
  - [ ] From `--file` flag
  - [ ] From `--inline` flag (for short translations)
- [ ] Call `Poflow.Translate.run/2`
- [ ] Handle errors with helpful messages

**6.3 Translate Tests** (`test/poflow/translate_test.exs`)
- [ ] Test parsing translation input (valid format)
- [ ] Test parsing errors (invalid format)
- [ ] Test updating single entry
- [ ] Test updating multiple entries
- [ ] Test msgid not found (error handling)
- [ ] Test `--force` flag (ignore not found)
- [ ] Test stdout mode vs in-place mode
- [ ] Test multiline msgstr updates
- [ ] Test preserving comments and references

**6.4 Integration Tests**
- [ ] Test stdin input with heredoc:
  ```bash
  mix poflow.translate --language sv <<EOF
  Sign In = Logga in
  Sign Out = Logga ut
  EOF
  ```
- [ ] Test inline mode: `mix poflow.translate --language sv --inline "Welcome = Välkommen"`
- [ ] Test file input: `mix poflow.translate --language sv --file translations.txt`

**Deliverable:** Working translate command with stdin/file/inline input

---

### Phase 7: Edit Command

**Goal:** Implement msgid editing across all language files

#### Tasks

**7.1 Editor Module** (`lib/poflow/editor.ex`)
- [ ] Implement `update_msgid_in_file/4` (file, old, new, dry_run)
  - [ ] Parse file
  - [ ] Find entries matching old msgid
  - [ ] Update msgid (preserve msgstr!)
  - [ ] Update msgid in `raw_lines` (preserve formatting)
  - [ ] Write to temp file, then rename
- [ ] Implement `update_msgid_in_raw_lines/2` helper
  - Replace msgid lines while preserving comments/references
- [ ] Implement `update_msgid_with_sources/5` (also update source files)
  - [ ] Extract source file references from `#:` comments
  - [ ] Parse references: `"file.ex:123"` format
  - [ ] Update each source file
- [ ] Implement `update_source_file/3` (file, old, new)
  - [ ] Read source file
  - [ ] Replace `"old msgid"` with `"new msgid"` (regex-based)
  - [ ] Write back if changed

**7.2 Mix Task: edit** (`lib/mix/tasks/poflow.edit.ex`)
- [ ] Define Mix task with `@shortdoc`
- [ ] Parse arguments: `old_msgid new_msgid --dry-run`
- [ ] Load config to find all .po files
- [ ] Find .pot file if exists
- [ ] Update each file (call `Editor.update_msgid_with_sources/5`)
- [ ] Print summary: files updated, entries changed
- [ ] Handle `--dry-run` flag (show what would change)

**7.3 Editor Tests** (`test/poflow/editor_test.exs`)
- [ ] Test updating msgid in single file
- [ ] Test preserving msgstr (translations)
- [ ] Test preserving comments and references
- [ ] Test dry-run mode (no file changes)
- [ ] Test source file updates
- [ ] Test with missing source files (graceful handling)

**Deliverable:** Working edit command that updates msgid across all files

---

### Phase 8: Documentation & Polish

**Goal:** Complete documentation and prepare for release

#### Tasks

**8.1 Main API Documentation** (`lib/poflow.ex`)
- [ ] Write module documentation with examples
- [ ] Document each public function with `@doc`
- [ ] Add `@spec` type specifications
- [ ] Include usage examples for programmatic API

**8.2 README** (`README.md`)
- [ ] Project overview and features
- [ ] Installation instructions (`{:poflow, "~> 0.1.0"}`)
- [ ] Quick start guide
- [ ] Configuration section (Phoenix config example)
- [ ] Mix tasks documentation:
  - `mix poflow.search`
  - `mix poflow.searchvalue`
  - `mix poflow.listempty`
  - `mix poflow.translate`
  - `mix poflow.edit`
- [ ] Programmatic API examples
- [ ] LLM usage guide (stdin patterns)
- [ ] Contributing section

**8.3 Hex Package Preparation**
- [ ] Set up `mix.exs` metadata:
  - description, licenses, links, maintainers
- [ ] Add `LICENSE` file
- [ ] Add `CHANGELOG.md`
- [ ] Generate docs: `mix docs`
- [ ] Review ExDoc output

**8.4 Testing & CI**
- [ ] Ensure all tests pass: `mix test`
- [ ] Add test coverage tool (`:excoveralls`)
- [ ] Set up GitHub Actions (if applicable)
- [ ] Test on different Elixir/OTP versions

**Deliverable:** Complete, documented package ready for Hex.pm

---

### Phase 9: MCP Server (Experimental)

**Goal:** Add MCP server support using Vancouver library

#### Tasks

**9.1 Research Vancouver**
- [ ] Read Vancouver documentation
- [ ] Understand MCP protocol (JSON-RPC 2.0 over stdio)
- [ ] Review example MCP servers
- [ ] Decide on tool definitions

**9.2 MCP Server Module** (`lib/poflow/mcp_server.ex`)
- [ ] Define MCP tools (list of available poflow commands)
  - Tool: `search_translations`
  - Tool: `search_translation_values`
  - Tool: `list_empty_translations`
  - Tool: `merge_translations`
  - Tool: `edit_msgid`
- [ ] Implement tool handlers (call existing `Poflow` functions)
- [ ] Handle tool call requests (parse JSON-RPC)
- [ ] Format responses (JSON-RPC result format)
- [ ] Handle errors (JSON-RPC error format)

**9.3 MCP Entry Point**
- [ ] Create `mix poflow.mcp` task (or escript)
- [ ] Start MCP server (stdio communication)
- [ ] Handle protocol handshake
- [ ] Loop: read requests → dispatch → send responses

**9.4 MCP Testing**
- [ ] Test with MCP client (e.g., Claude Desktop)
- [ ] Test each tool call
- [ ] Test error handling
- [ ] Document MCP server usage

**9.5 MCP Documentation**
- [ ] Add MCP server section to README
- [ ] Document how to configure in Claude Desktop
- [ ] Provide example tool usage from LLM perspective

**Deliverable:** Working MCP server for poflow tools

---

## Testing Strategy

### Unit Tests
- Test each module in isolation
- Use ExUnit test cases
- Mock file I/O where appropriate (use fixtures)

### Integration Tests
- Test Mix tasks end-to-end
- Use temporary directories for file operations
- Test stdin/stdout with captured I/O

### Test Fixtures
- Create `test/fixtures/` directory
- Include sample .po files:
  - Empty file
  - Single entry
  - Multiple entries
  - Multi-line entries
  - Entries with comments/references

### Property-Based Testing (Optional)
- Use StreamData for parser testing
- Generate random .po files
- Test round-trip: parse → format → parse

---

## Configuration Examples

### Phoenix Project Config

```elixir
# config/config.exs
config :poflow,
  gettext_path: "priv/gettext"
```

### Standalone Project Config

```elixir
# config/config.exs
import Config

config :poflow,
  gettext_path: "translations"

import_config "#{config_env()}.exs"
```

---

## Usage Examples

### Programmatic API (from Phoenix app)

```elixir
# In a Phoenix LiveView
defmodule MyAppWeb.TranslationLive do
  use MyAppWeb, :live_view

  def handle_event("translate", %{"text" => translations}, socket) do
    case Poflow.translate(translations, language: "sv") do
      {:ok, result} ->
        {:noreply, put_flash(socket, :info, "Translated #{result.updated} entries")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{reason}")}
    end
  end
end
```

### Mix Tasks

```bash
# Search for entries
mix poflow.search "Welcome" --language sv --json

# List untranslated entries
mix poflow.listempty --language sv --limit 10

# Translate from stdin (heredoc)
mix poflow.translate --language sv <<EOF
Sign In = Logga in
Sign Out = Logga ut
EOF

# Translate inline (short)
mix poflow.translate --language sv --inline "Welcome = Välkommen"

# Edit msgid across all files
mix poflow.edit "Sign In" "Log In"
mix poflow.edit --dry-run "Sign In" "Log In"
```

### Piping and Composition

```bash
# Find empty entries and save as JSON
mix poflow.listempty --language sv --json > empty.json

# Search and pipe to another tool
mix poflow.search "error" --language sv | grep "line 42"

# Chain with jq
mix poflow.search "Welcome" --json | jq '.msgstr'
```

---

## Migration Path (Go → Elixir)

For users currently using the Go version:

1. **Install Elixir version**: Add to `mix.exs` deps
2. **Update config**: Move settings from `poflow.yml` to `config/config.exs`
3. **Update scripts**: Replace `poflow translate ...` with `mix poflow.translate ...`
4. **No file needed**: Can pass translations via stdin/heredoc instead of temp files

---

## Success Criteria

### Phase 1-2: Core Functionality
- ✅ Parser can stream large .po files
- ✅ Config resolves paths correctly
- ✅ Tests pass for parser and config

### Phase 3-7: All Commands Working
- ✅ All Mix tasks implemented and tested
- ✅ Can search, list empty, translate, and edit
- ✅ Stdin/file/language input patterns work
- ✅ JSON output works for all commands

### Phase 8: Ready for Release
- ✅ Comprehensive documentation
- ✅ Published to Hex.pm
- ✅ Can be used in Phoenix projects
- ✅ Programmatic API works as expected

### Phase 9: MCP Integration
- ✅ MCP server works with Claude Desktop
- ✅ All tools callable from LLM
- ✅ Documented for LLM users

---

## Timeline Estimates

| Phase | Estimated Time |
|-------|----------------|
| Phase 1: Core Parsing | 1 day |
| Phase 2: Config | 0.5 days |
| Phase 3: Output | 0.5 days |
| Phase 4: Search | 1 day |
| Phase 5: List Empty | 0.5 days |
| Phase 6: Translate | 1.5 days |
| Phase 7: Edit | 1 day |
| Phase 8: Documentation | 1 day |
| Phase 9: MCP Server | 1-2 days |
| **Total** | **7-8 days** |

*Note: Times are for an experienced Elixir developer working part-time*

---

## Dependencies

### Required Hex Packages

```elixir
defp deps do
  [
    {:ex_doc, "~> 0.31", only: :dev, runtime: false}  # Documentation
    # JSON support is built-in to Elixir 1.18+
  ]
end
```

### Optional (MCP Phase)

```elixir
{:vancouver, "~> 0.1"}  # MCP server library (if suitable)
# OR roll custom JSON-RPC stdio handler
```

---

## Key Differences from Go Version

| Aspect | Go Version | Elixir Version |
|--------|-----------|----------------|
| **Distribution** | Single binary | Hex package |
| **CLI** | Cobra commands | Mix tasks |
| **Config** | YAML file | Phoenix config |
| **Translation input** | File or stdin | String/stdin/file |
| **Usage in code** | `System.cmd("poflow", ...)` | `Poflow.translate(...)` |
| **Dependencies** | None (static binary) | Erlang/Elixir runtime |
| **Concurrency** | Go routines | Processes/streams |
| **Pattern matching** | if/else chains | Native pattern matching |

---

## Future Enhancements (Post-Release)

- [ ] Escript compilation (optional standalone binary)
- [ ] Plural forms support (`msgid_plural`, `msgstr[0]`, etc.)
- [ ] Context support (`msgctxt`)
- [ ] Fuzzy translation matching (`#, fuzzy` flag)
- [ ] Translation memory / suggestion engine
- [ ] Web UI (Phoenix LiveView)
- [ ] VS Code extension integration

---

## Notes

- **No file permissions needed**: Passing translations as strings (heredoc/stdin) avoids Claude Code asking for file write permissions
- **Streaming is key**: Must maintain streaming architecture for large files (Phoenix projects can have 1000+ entries)
- **Test with real Phoenix project**: Before Hex release, dogfood in actual Phoenix app
- **MCP is experimental**: Vancouver may not be the right fit; evaluate alternatives
- **Keep it simple**: Match Go version feature parity first, don't over-engineer

---

## Getting Started

To begin implementation:

1. **Create project**: `mix new poflow`
2. **Start with Phase 1**: Build parser first (most critical component)
3. **Test incrementally**: Write tests alongside implementation
4. **Use Go code as reference**: Port logic but adapt to Elixir idioms
5. **Document as you go**: Add `@doc` and examples while fresh

---

## Questions to Resolve

- [ ] Should MCP server be separate package or optional in main package?
- [ ] Escript vs Mix task for MCP server entry point?
- [ ] Vancouver vs custom JSON-RPC implementation?
- [ ] Should we support both `config.exs` and optional YAML for non-Phoenix projects?
- [ ] Naming: `Poflow.Translate.run/2` vs `Poflow.translate/2`?

---

**Ready to start Phase 1!** 🚀
