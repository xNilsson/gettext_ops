defmodule GettextOps do
  @moduledoc """
  Targeted operations for Phoenix Gettext translations.

  **gettext_ops** provides functions for searching, listing, and updating Phoenix Gettext
  translation files without loading entire files into memory. It's designed to be token-efficient
  for AI agents and scriptable for automation.

  ## Features

  - 🎯 **Targeted queries** - Get only the entries you need, not entire files
  - 📝 **Bulk operations** - Update multiple translations at once
  - 🔄 **Global edits** - Change msgid across all language files in one command
  - 🤖 **LLM-friendly** - JSON output for easy parsing by AI tools
  - ⚡ **Fast** - Built on Expo for reliable .po file handling
  - 🔧 **Phoenix-native** - Works with standard `priv/gettext` structure

  ## Quick Start

  ```elixir
  # List untranslated entries
  {:ok, messages} = GettextOps.list_untranslated(locale: "sv", limit: 10)

  # Search for entries
  {:ok, messages} = GettextOps.search("Welcome", locale: "sv")

  # Update translations
  translations = %{"Sign In" => "Logga in", "Sign Out" => "Logga ut"}
  {:ok, result} = GettextOps.translate(translations, locale: "sv")

  # Change msgid globally
  {:ok, result} = GettextOps.change_msgid("Old Text", "New Text")
  ```

  ## Configuration

  Configure in `config/config.exs`:

  ```elixir
  config :gettext_ops,
    gettext_path: "priv/gettext",
    default_domain: "default"
  ```

  ## Mix Tasks

  All operations are also available as Mix tasks:

  - `mix gettext_ops.list_untranslated` - List entries with empty translations
  - `mix gettext_ops.search` - Search by msgid (source text)
  - `mix gettext_ops.search_value` - Search by msgstr (translation)
  - `mix gettext_ops.translate` - Apply translations from file or stdin
  - `mix gettext_ops.change_msgid` - Update msgid across all files

  See individual task documentation for detailed usage.

  ## Token Efficiency for LLMs

  Instead of reading a 5000-line .po file (~15k tokens), use targeted queries
  to get exactly what you need (~500 tokens for 10 entries). This makes
  gettext_ops ideal for AI agent workflows.

  ## Built on Expo

  gettext_ops uses the [Expo](https://hex.pm/packages/expo) library for .po file
  parsing and writing - the same library used by Phoenix's Gettext module.
  """

  alias GettextOps.Operations.{ListUntranslated, Search, SearchValue, Translate, ChangeMsgid}

  @doc """
  List all entries with empty translations for a given locale.

  Returns `{:ok, messages}` containing a list of `Expo.Message` structs,
  or `{:error, reason}` if the operation fails.

  ## Options

  - `:locale` - (required) Target locale code (e.g., "sv", "en", "de")
  - `:domain` - Gettext domain (defaults to configured default_domain)
  - `:limit` - Maximum number of results to return

  ## Examples

      # List all untranslated Swedish entries
      {:ok, messages} = GettextOps.list_untranslated(locale: "sv")

      # Get first 10 entries (useful for LLMs)
      {:ok, messages} = GettextOps.list_untranslated(locale: "sv", limit: 10)

      # Specific domain
      {:ok, messages} = GettextOps.list_untranslated(locale: "sv", domain: "errors")

  """
  @spec list_untranslated(keyword()) :: {:ok, [Expo.Message.t()]} | {:error, term()}
  def list_untranslated(opts) when is_list(opts) do
    ListUntranslated.run(opts)
  end

  @doc """
  Search for entries where msgid (source text) matches a pattern.

  The pattern can be a string (case-insensitive substring match) or a regex.

  ## Options

  - `:locale` - (required) Target locale
  - `:domain` - Gettext domain (defaults to configured default_domain)
  - `:regex` - If true, treat pattern as regex (default: false)
  - `:limit` - Maximum number of results

  ## Examples

      # Find entries containing "Welcome"
      {:ok, messages} = GettextOps.search("Welcome", locale: "sv")

      # Regex search for entries starting with "Error"
      {:ok, messages} = GettextOps.search("^Error", locale: "sv", regex: true)

      # Limit results
      {:ok, messages} = GettextOps.search("button", locale: "sv", limit: 5)

  """
  @spec search(String.t(), keyword()) :: {:ok, [Expo.Message.t()]} | {:error, term()}
  def search(pattern, opts) when is_binary(pattern) and is_list(opts) do
    Search.run(pattern, opts)
  end

  @doc """
  Search for entries where msgstr (translated text) matches a pattern.

  The pattern can be a string (case-insensitive substring match) or a regex.

  ## Options

  Same as `search/2`.

  ## Examples

      # Find Swedish translations containing "Välkommen"
      {:ok, messages} = GettextOps.search_value("Välkommen", locale: "sv")

      # Find all translations with "fel" (Swedish for error/wrong)
      {:ok, messages} = GettextOps.search_value("fel", locale: "sv")

  """
  @spec search_value(String.t(), keyword()) :: {:ok, [Expo.Message.t()]} | {:error, term()}
  def search_value(pattern, opts) when is_binary(pattern) and is_list(opts) do
    SearchValue.run(pattern, opts)
  end

  @doc """
  Apply translations to a .po file.

  Updates msgstr values for the given msgid keys in the specified locale's .po file.

  ## Parameters

  - `translations` - Map of msgid => msgstr translations to apply
  - `opts` - Keyword list of options

  ## Options

  - `:locale` - (required) Target locale
  - `:domain` - Gettext domain (defaults to configured default_domain)

  ## Examples

      # Apply translations
      translations = %{
        "Sign In" => "Logga in",
        "Sign Out" => "Logga ut",
        "Welcome" => "Välkommen"
      }
      {:ok, %{updated: 3, not_found: []}} = GettextOps.translate(translations, locale: "sv")

      # Handle missing msgids
      {:ok, result} = GettextOps.translate(%{"Missing" => "Saknas"}, locale: "sv")
      # => {:ok, %{updated: 0, not_found: ["Missing"]}}

  """
  @spec translate(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def translate(translations, opts) when is_map(translations) and is_list(opts) do
    Translate.run(translations, opts)
  end

  @doc """
  Change a msgid (source text) across all locale files and .pot templates.

  This updates the msgid in all .po files and .pot templates while preserving
  existing translations. Useful for refactoring translation keys across the codebase.

  ## Parameters

  - `old_msgid` - Current msgid to replace
  - `new_msgid` - New msgid text
  - `opts` - Keyword list of options

  ## Options

  - `:domain` - Gettext domain (defaults to configured default_domain)
  - `:dry_run` - If true, preview changes without modifying files (default: false)

  ## Examples

      # Update msgid everywhere
      {:ok, %{files: 3, entries: 5}} = GettextOps.change_msgid("Sign In", "Log In")

      # Preview changes first
      {:ok, %{files: 3, entries: 5}} = GettextOps.change_msgid("Sign In", "Log In", dry_run: true)

      # Specific domain
      {:ok, result} = GettextOps.change_msgid("Old", "New", domain: "errors")

  """
  @spec change_msgid(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def change_msgid(old_msgid, new_msgid, opts \\ [])
      when is_binary(old_msgid) and is_binary(new_msgid) and is_list(opts) do
    ChangeMsgid.run(old_msgid, new_msgid, opts)
  end
end
