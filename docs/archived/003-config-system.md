# Task 003: Config and Path Resolution

**Status:** `completed`
**Created:** 2025-10-15
**Depends On:** `001`
**Can Be Parallelized:** Yes (can work on in parallel with 002)

---

## Goal

Implement configuration system and path resolution for finding .po files in Phoenix project structure.

---

## Context

gettext_ops needs to locate .po files in the standard Phoenix Gettext structure: `priv/gettext/{locale}/LC_MESSAGES/{domain}.po`. Configuration should be read from Phoenix's `config.exs` file, with sensible defaults.

For reference, the originial `poflow` implementation in go can be found at: ~/code/poflow

---

## Deliverables

- [ ] `GettextOps.Config` module
- [ ] Read config from Application environment
- [ ] Resolve locale-specific .po file paths
- [ ] Find all available locales
- [ ] Tests for path resolution
- [ ] Documentation for config options

---

## Implementation Notes

### Key Decisions
- Default `gettext_path` is `"priv/gettext"`
- Default `domain` is `"default"`
- Support finding .pot template files
- List all available .po files recursively

### Configuration Format
```elixir
# config/config.exs
config :gettext_ops,
  gettext_path: "priv/gettext",
  default_domain: "default"
```

### API Design
```elixir
defmodule GettextOps.Config do
  @doc "Get the configured gettext path"
  @spec gettext_path() :: String.t()
  def gettext_path()

  @doc "Get the default domain"
  @spec default_domain() :: String.t()
  def default_domain()

  @doc "Resolve path to a locale's .po file"
  @spec po_file_path(locale :: String.t(), domain :: String.t()) :: String.t()
  def po_file_path(locale, domain \\ nil)

  @doc "Find the .pot template file"
  @spec pot_file_path(domain :: String.t()) :: String.t() | nil
  def pot_file_path(domain \\ nil)

  @doc "List all available .po files"
  @spec list_po_files() :: [String.t()]
  def list_po_files()

  @doc "List all available locales"
  @spec list_locales() :: [String.t()]
  def list_locales()

  @doc "Check if a .po file exists for given locale"
  @spec locale_exists?(String.t()) :: boolean()
  def locale_exists?(locale)
end
```

### Path Resolution Logic
```elixir
# For locale "sv" and domain "default"
# => "priv/gettext/sv/LC_MESSAGES/default.po"

# For .pot template
# => "priv/gettext/default.pot"

# List all locales by scanning directory structure
# priv/gettext/sv/ → "sv"
# priv/gettext/en/ → "en"
```

---

## Testing Requirements

### Unit Tests
- [ ] Test reading config from Application environment
- [ ] Test default values when config not set
- [ ] Test `po_file_path/2` resolution
- [ ] Test `pot_file_path/1` resolution
- [ ] Test `list_po_files/0` with fixture directory
- [ ] Test `list_locales/0` extracts locales correctly
- [ ] Test `locale_exists?/1` validation

### Test Setup
- [ ] Create fixture directory structure:
  ```
  test/fixtures/gettext/
  ├── sv/
  │   └── LC_MESSAGES/
  │       └── default.po
  ├── en/
  │   └── LC_MESSAGES/
  │       └── default.po
  └── default.pot
  ```

---

## Acceptance Criteria

- [ ] Config reads from Application environment
- [ ] Path resolution matches Phoenix conventions
- [ ] Can list all available locales
- [ ] Can check if locale exists
- [ ] All tests passing
- [ ] Functions documented with @doc and @spec
- [ ] Config options documented in module @moduledoc

---

## Progress Log

### 2025-10-15 - Task Completed

**Implementation:**
- Created test fixture directory structure with sample .po files for `en` and `sv` locales
- Implemented complete `GettextOps.Config` module with all required functions:
  - `gettext_path/0` - Read config from Application environment with default
  - `default_domain/0` - Read domain config with default
  - `po_file_path/2` - Resolve locale-specific .po file paths
  - `pot_file_path/1` - Resolve .pot template paths
  - `list_po_files/0` - Recursively find all .po files
  - `list_locales/0` - Extract locale codes from directory structure
  - `locale_exists?/1` - Check if a locale is available
- All functions include proper `@doc` and `@spec` annotations
- Module includes comprehensive `@moduledoc` with configuration examples

**Testing:**
- Created comprehensive test suite in `test/gettext_ops/config_test.exs`
- Tests cover all functions with multiple scenarios
- Tests validate default values and custom configuration
- Tests use fixture directory for filesystem-dependent tests
- All 28 tests passing (8 doctests + 20 unit tests)

**Decisions:**
- Removed filesystem-dependent examples from doctests to avoid false failures
- Used `Path.wildcard/1` for efficient .po file discovery
- Functions return empty lists instead of raising errors when directories don't exist
- Configuration uses standard Elixir `Application.get_env/3` pattern

---

## Related Files

- `lib/gettext_ops/config.ex`
- `test/gettext_ops/config_test.exs`
- `test/fixtures/gettext/` (directory structure)

---

## References

- Phoenix Gettext directory structure: https://hexdocs.pm/gettext/Gettext.html#module-directory-structure
- Application config: https://hexdocs.pm/elixir/Application.html#get_env/3
