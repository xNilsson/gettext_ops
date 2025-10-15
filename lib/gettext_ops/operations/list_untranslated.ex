defmodule GettextOps.Operations.ListUntranslated do
  @moduledoc """
  List untranslated entries operation for finding entries with empty translations.

  This module provides functionality to list all translation entries
  in .po files that have empty msgstr fields. This is one of the most
  frequently used operations for developers and LLM agents, as it provides
  exactly the entries that need translation without loading entire files.

  ## Token Efficiency

  Instead of reading a 5000-line .po file (~15k tokens), this operation
  returns only the untranslated entries (e.g., 10 entries ~500 tokens).

  ## Options

  - `:locale` - (required) The locale to list untranslated entries from (e.g., "sv", "en")
  - `:domain` - The domain to search in (defaults to configured default_domain)
  - `:limit` - Maximum number of results to return (default: nil for unlimited)

  ## Examples

      # List all untranslated entries
      {:ok, messages} = GettextOps.Operations.ListUntranslated.run(locale: "sv")

      # Limit results (useful for LLMs)
      {:ok, messages} = GettextOps.Operations.ListUntranslated.run(locale: "sv", limit: 10)

      # Specific domain
      {:ok, messages} = GettextOps.Operations.ListUntranslated.run(locale: "sv", domain: "errors")

  """

  alias GettextOps.{Config, Parser, Entry}
  alias Expo.Message

  @doc """
  List all untranslated entries for a given locale.

  Returns `{:ok, messages}` on success or `{:error, reason}` on failure.

  ## Parameters

  - `opts` - Keyword list of options (see module documentation)

  ## Examples

      # List all untranslated entries
      GettextOps.Operations.ListUntranslated.run(locale: "sv")
      # => {:ok, [%Expo.Message.Singular{msgid: ["Profile settings"], msgstr: [""]}, ...]}

      # List with limit
      GettextOps.Operations.ListUntranslated.run(locale: "sv", limit: 5)
      # => {:ok, [%Expo.Message.Singular{...}, ...]} (max 5 entries)

  """
  @spec run(keyword()) :: {:ok, [Message.t()]} | {:error, term()}
  def run(opts) do
    # Extract options
    locale = Keyword.fetch!(opts, :locale)
    domain = Keyword.get(opts, :domain)
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
        do_list_untranslated(po_path, limit)
      end
    end
  end

  # Perform the actual listing
  @spec do_list_untranslated(String.t(), non_neg_integer() | nil) ::
          {:ok, [Message.t()]} | {:error, term()}
  defp do_list_untranslated(po_path, limit) do
    # Parse and filter for untranslated messages
    case Parser.parse_and_filter(po_path, &Entry.untranslated?/1) do
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
end
