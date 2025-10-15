# Task 010: MCP Server (Optional)

**Status:** `not-started`
**Created:** 2025-10-15
**Depends On:** `005, 006, 007, 008` (all feature tasks)
**Can Be Parallelized:** Yes (can be done after core features, independent of 009)

---

## Goal

Add MCP (Model Context Protocol) server support to enable direct tool integration with Claude Desktop and other LLM clients.

---

## Context

MCP allows AI assistants to call gettext_ops functions as tools directly, without needing to shell out to Mix tasks. This is experimental and should be clearly marked as such.

**Note:** This task is optional and can be skipped for the initial release. Evaluate if MCP integration adds significant value over stdin/stdout Mix tasks.

---

## Deliverables

- [ ] Research MCP protocol and available Elixir libraries
- [ ] Design MCP tool definitions
- [ ] Implement MCP server module
- [ ] Create entry point (Mix task or escript)
- [ ] Test with Claude Desktop
- [ ] Document MCP setup
- [ ] Optional: Separate Hex package vs main package

---

## Implementation Notes

### Key Decisions
- Evaluate Vancouver library vs custom JSON-RPC implementation
- Use stdio communication (standard for MCP)
- Define 5 tools matching the 5 commands
- Keep MCP server optional (don't require it for basic usage)

### MCP Tool Definitions
```json
{
  "tools": [
    {
      "name": "list_untranslated",
      "description": "List untranslated entries in a locale",
      "input_schema": {
        "type": "object",
        "properties": {
          "locale": {"type": "string"},
          "limit": {"type": "number"},
          "domain": {"type": "string"}
        },
        "required": ["locale"]
      }
    },
    {
      "name": "search",
      "description": "Search for entries by msgid",
      "input_schema": {
        "type": "object",
        "properties": {
          "pattern": {"type": "string"},
          "locale": {"type": "string"},
          "regex": {"type": "boolean"},
          "limit": {"type": "number"}
        },
        "required": ["pattern", "locale"]
      }
    },
    {
      "name": "search_value",
      "description": "Search for entries by msgstr",
      "input_schema": {
        "type": "object",
        "properties": {
          "pattern": {"type": "string"},
          "locale": {"type": "string"},
          "regex": {"type": "boolean"},
          "limit": {"type": "number"}
        },
        "required": ["pattern", "locale"]
      }
    },
    {
      "name": "translate",
      "description": "Update translations in a locale",
      "input_schema": {
        "type": "object",
        "properties": {
          "translations": {"type": "string"},
          "locale": {"type": "string"},
          "force": {"type": "boolean"}
        },
        "required": ["translations", "locale"]
      }
    },
    {
      "name": "change_msgid",
      "description": "Change msgid across all locales",
      "input_schema": {
        "type": "object",
        "properties": {
          "old_msgid": {"type": "string"},
          "new_msgid": {"type": "string"},
          "dry_run": {"type": "boolean"}
        },
        "required": ["old_msgid", "new_msgid"]
      }
    }
  ]
}
```

### API Design

**MCP Server Module:**
```elixir
defmodule GettextOps.MCP.Server do
  @doc "Start MCP server (stdio communication)"
  def start()

  @doc "Handle tool call request"
  def handle_tool_call(tool_name, params)

  @doc "List available tools"
  def list_tools()
end
```

**Mix Task Entry Point:**
```elixir
defmodule Mix.Tasks.GettextOps.Mcp do
  use Mix.Task

  @shortdoc "Start MCP server for gettext_ops tools"

  def run(_args) do
    GettextOps.MCP.Server.start()
  end
end
```

### Claude Desktop Configuration
```json
{
  "mcpServers": {
    "gettext_ops": {
      "command": "mix",
      "args": ["gettext_ops.mcp"],
      "cwd": "/path/to/phoenix/project"
    }
  }
}
```

---

## Testing Requirements

### Research Phase
- [ ] Test Vancouver library with simple example
- [ ] Review MCP protocol specification
- [ ] Test JSON-RPC stdio communication
- [ ] Evaluate if MCP adds value over Mix tasks

### Implementation Tests
- [ ] Test each tool call handler
- [ ] Test error handling
- [ ] Test with Claude Desktop
- [ ] Test concurrent requests
- [ ] Test long-running operations

---

## Acceptance Criteria

**If implementing MCP:**
- [ ] MCP server starts successfully
- [ ] All 5 tools callable from Claude Desktop
- [ ] Tool calls return correct results
- [ ] Error handling works
- [ ] Documented setup process
- [ ] Tests passing

**If skipping MCP:**
- [ ] Decision documented in task
- [ ] Alternative approach noted (stdin/stdout is sufficient)
- [ ] Task marked as "skipped"

---

## Progress Log

_Updates will be added here as work progresses_

---

## Related Files

- `lib/gettext_ops/mcp/server.ex` (if implemented)
- `lib/mix/tasks/gettext_ops.mcp.ex` (if implemented)
- `test/gettext_ops/mcp/server_test.exs` (if implemented)

---

## References

- MCP Protocol: https://modelcontextprotocol.io/
- Vancouver library: https://hex.pm/packages/vancouver (if exists)
- JSON-RPC 2.0: https://www.jsonrpc.org/specification
- Claude Desktop MCP guide: https://docs.anthropic.com/claude/docs/model-context-protocol

---

## Decision Point

Before starting implementation, decide:

1. **Is MCP needed?** Mix tasks with stdin/stdout already work well with LLMs
2. **Separate package?** Should MCP be in `gettext_ops_mcp` package?
3. **Which library?** Vancouver, custom implementation, or wait for mature library?

Consider deferring this task to v0.2.0 if the core functionality (Mix tasks) meets user needs.
