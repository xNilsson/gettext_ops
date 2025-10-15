defmodule GettextOps.Operations.SearchValue do
  @moduledoc """
  Search operation for finding translation entries by msgstr (translated text).

  This module provides functionality to search for translation entries
  in .po files by their msgstr field (the actual translations), supporting
  both substring matching (case-insensitive by default) and regex patterns.

  ## Options

  - `:locale` - (required) The locale to search in (e.g., "sv", "en")
  - `:domain` - The domain to search in (defaults to configured default_domain)
  - `:regex` - Boolean, if true treats pattern as regex (default: false)
  - `:limit` - Maximum number of results to return (default: nil for unlimited)
  - `:json` - Boolean, if true returns results in JSON format (default: false)

  ## Examples

      # Substring search (case-insensitive)
      {:ok, messages} = GettextOps.Operations.SearchValue.run("välkommen", locale: "sv")

      # Regex search
      {:ok, messages} = GettextOps.Operations.SearchValue.run("^Fel", locale: "sv", regex: true)

      # Limited results
      {:ok, messages} = GettextOps.Operations.SearchValue.run("knapp", locale: "sv", limit: 5)

  """

  alias GettextOps.{Config, Parser, Entry}
  alias Expo.Message

  @doc """
  Search for translation entries by msgstr (translated text).

  Returns `{:ok, messages}` on success or `{:error, reason}` on failure.

  ## Parameters

  - `pattern` - String pattern to search for
  - `opts` - Keyword list of options (see module documentation)

  ## Examples

      # Substring search
      GettextOps.Operations.SearchValue.run("Välkommen", locale: "sv")
      # => {:ok, [%Expo.Message.Singular{msgid: ["Welcome to Phoenix!"], msgstr: ["Välkommen till Phoenix!"]}, ...]}

      # Regex search for translations starting with "Fel"
      GettextOps.Operations.SearchValue.run("^Fel", locale: "sv", regex: true)
      # => {:ok, [%Expo.Message.Singular{msgid: ["Error: Invalid input"], msgstr: ["Fel: Ogiltig inmatning"]}, ...]}

  """
  @spec run(String.t(), keyword()) :: {:ok, [Message.t()]} | {:error, term()}
  def run(pattern, opts) when is_binary(pattern) do
    # Extract options
    locale = Keyword.fetch!(opts, :locale)
    domain = Keyword.get(opts, :domain)
    use_regex = Keyword.get(opts, :regex, false)
    limit = Keyword.get(opts, :limit)

    # Validate locale exists
    unless Config.locale_exists?(locale) do
      {:error, "Locale '#{locale}' not found"}
    else
      # Get the .po file path
      po_path = Config.po_file_path(locale, domain)

      # Check if file exists
      unless File.exists?(po_path) do
        {:error, "File not found: #{po_path}"}
      else
        do_search(po_path, pattern, use_regex, limit)
      end
    end
  end

  # Perform the actual search
  @spec do_search(String.t(), String.t(), boolean(), non_neg_integer() | nil) ::
          {:ok, [Message.t()]} | {:error, term()}
  defp do_search(po_path, pattern, use_regex, limit) do
    # Build the search pattern
    search_pattern = build_pattern(pattern, use_regex)

    # Parse and filter messages by msgstr
    case Parser.parse_and_filter(po_path, &Entry.matches_msgstr?(&1, search_pattern)) do
      {:ok, messages} ->
        # Apply limit if specified
        limited_messages =
          if limit do
            Enum.take(messages, limit)
          else
            messages
          end

        {:ok, limited_messages}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Build search pattern based on regex option
  @spec build_pattern(String.t(), boolean()) :: String.t() | Regex.t()
  defp build_pattern(pattern, true) do
    # Regex mode - compile with case-insensitive flag
    Regex.compile!(pattern, "i")
  end

  defp build_pattern(pattern, false) do
    # Substring mode - create case-insensitive regex
    escaped = Regex.escape(pattern)
    Regex.compile!(escaped, "i")
  end
end
