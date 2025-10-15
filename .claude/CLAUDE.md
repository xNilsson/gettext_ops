# gettext_ops - AI Agent Workflow Guide

## Project Overview

**gettext_ops** is an Elixir library providing Mix tasks for targeted operations on Phoenix Gettext translation files. This is a port of the Go CLI tool `poflow`, adapted for native Elixir/Phoenix integration.

**Goal:** Build a Hex package with Mix tasks for searching, listing, translating, and editing .po files without loading entire files into memory.

## Key Information

### Technology Stack
- **Language:** Elixir 1.18+
- **Parser:** [Expo](https://hex.pm/packages/expo) - Official .po file parser used by Phoenix Gettext
- **JSON:** Built-in [JSON module](https://hexdocs.pm/elixir/1.18/JSON.html) for encoding/decoding (Elixir 1.18+)
- **Testing:** ExUnit with test fixtures

### Core Principles

1. **Use Expo for all .po parsing** - Never write custom parsers
2. **Never read entire .po files** - Use streaming where possible
3. **Match Phoenix conventions** - Use `priv/gettext/{locale}/LC_MESSAGES/{domain}.po`
4. **LLM-friendly APIs** - JSON output, stdin/stdout patterns
5. **Test-driven** - Write tests alongside implementation

### Project Structure

```
lib/
├── gettext_ops.ex                      # Main public API
├── gettext_ops/
│   ├── config.ex                       # Config and path resolution
│   ├── operations/
│   │   ├── list_untranslated.ex       # List empty translations
│   │   ├── search.ex                   # Search by msgid
│   │   ├── search_value.ex             # Search by msgstr
│   │   ├── translate.ex                # Update translations
│   │   └── change_msgid.ex             # Edit msgid globally
│   └── mix/
│       └── tasks/
│           ├── gettext_ops.list_untranslated.ex
│           ├── gettext_ops.search.ex
│           ├── gettext_ops.search_value.ex
│           ├── gettext_ops.translate.ex
│           └── gettext_ops.change_msgid.ex
```

## Task-Based Workflow

This project uses a task-based workflow for organized development. Tasks are stored in `docs/tasks/` with numbered IDs.

### Quick Commands

```bash
/tasks                    # List all tasks with status and dependencies
/task [id]               # Start working on a specific task (e.g., /task 002)
/task-new [name]         # Create a new task from template
/task-complete           # Mark current task complete and archive it
```

### Task Workflow

1. **Check available tasks:** Use `/tasks` to see what's available
2. **Select a task:** Use `/task [id]` to start working
3. **Implement:** Follow the deliverables and acceptance criteria in the task file
4. **Update progress:** Add notes to the task's Progress Log section
5. **Complete:** Use `/task-complete` when done (moves to `docs/archived/`)

### Task Dependencies

Some tasks must be done sequentially (dependencies), others can be parallelized:

**Sequential Core:**
- 001 (setup) → 002 (parsing) → 003 (config) → 004 (output)

**Parallel Features (after 004):**
- 005 (search), 006 (list), 007 (translate), 008 (change_msgid)

**Final:**
- 009 (documentation) - depends on all features
- 010 (MCP server) - optional, experimental

## API Naming Conventions

Based on the `readme-new.md`, the public API should be:

```elixir
# Mix tasks (user-facing commands)
mix gettext_ops.list_untranslated --locale sv --json
mix gettext_ops.search "pattern" --locale sv
mix gettext_ops.search_value "pattern" --locale sv
mix gettext_ops.translate --locale sv --file translations.txt
mix gettext_ops.change_msgid "old" "new"

# Programmatic API (library functions)
GettextOps.list_untranslated(locale: "sv", limit: 10)
GettextOps.search(pattern, locale: "sv", json: true)
GettextOps.search_value(pattern, locale: "sv")
GettextOps.translate(translations, locale: "sv")
GettextOps.change_msgid(old_msgid, new_msgid, dry_run: false)
```

**Note:** API is more descriptive than the original Go version (`list_untranslated` instead of `listempty`).

## Configuration

Phoenix projects configure gettext_ops in `config/config.exs`:

```elixir
config :gettext_ops,
  gettext_path: "priv/gettext",
  default_domain: "default"
```

## Testing Strategy

1. **Unit tests** - Test each operation module in isolation
2. **Integration tests** - Test Mix tasks end-to-end
3. **Fixtures** - Use `test/fixtures/` with sample .po files
4. **Streaming tests** - Verify memory efficiency with large files

## Important Reminders

### When Working on Tasks

- **Update task status** in the task file as you progress
- **Document decisions** in the Progress Log section
- **Run tests frequently** - `mix test`
- **Add @doc and @spec** to all public functions
- **Use Expo library** - Don't parse .po files manually

### Code Style

- Use `@moduledoc` for module documentation
- Use `@doc` for public function documentation
- Add `@spec` type specifications
- Follow Elixir naming conventions (snake_case)
- Keep functions small and focused

### Common Pitfalls to Avoid

- ❌ Don't read entire .po files into memory
- ❌ Don't write custom .po parsers (use Expo)
- ❌ Don't create new files when editing existing ones
- ❌ Don't forget to test with multi-line msgid/msgstr entries
- ❌ Don't hardcode paths (use config)

## References

- **Functionality reference:** See `readme-new.md` for complete feature descriptions
- **Original implementation:** `~/code/poflow` (Go version)
- **Port plan:** See `plan-port-elixir.md` for detailed implementation guide
- **Task template:** See `docs/template-task.md`

## Getting Help

If you encounter issues:

1. Check the current task file for context
2. Review the port plan (`plan-port-elixir.md`)
3. Look at the Go implementation (`~/code/poflow`)
4. Check Expo library docs: https://hex.pm/packages/expo

## Progress Tracking

Current tasks are in `docs/tasks/[id]-[name].md`
Completed tasks are in `docs/archived/[id]-[name].md`

Use `/tasks` to see the current state of all tasks.
