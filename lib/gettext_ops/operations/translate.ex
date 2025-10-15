defmodule GettextOps.Operations.Translate do
  @moduledoc """
  Translation update operation for bulk updating msgstr values in .po files.

  This module provides functionality to update translations in .po files
  from various input sources (stdin, file, or inline). It accepts translations
  in a simple format: `msgid = msgstr` (one per line).

  This is the **most important command** for the LLM workflow, enabling bulk
  translation updates without manually editing .po files.

  ## Input Format

  Each line should contain a msgid and msgstr separated by `=`:

      Sign In = Logga in
      Sign Out = Logga ut
      Welcome = Välkommen
      Error: Invalid input = Fel: Ogiltig inmatning

  Empty lines and lines starting with `#` are ignored.

  ## Atomic Updates

  Updates are performed atomically by writing to a temporary file and then
  renaming it to the original file. This prevents corruption if the operation
  fails midway.

  ## Options

  - `:locale` - (required) The locale to update (e.g., "sv", "en")
  - `:domain` - The domain to update (defaults to configured default_domain)
  - `:force` - Continue even if some msgids are not found (default: false)

  ## Examples

      # Parse translation input
      {:ok, translations} = GettextOps.Operations.Translate.parse_translations(\"\"\"
      Sign In = Logga in
      Sign Out = Logga ut
      \"\"\")

      # Apply translations
      {:ok, result} = GettextOps.Operations.Translate.run(translations, locale: "sv")
      # => {:ok, %{updated: 2, not_found: []}}

      # With force flag (ignore missing msgids)
      {:ok, result} = GettextOps.Operations.Translate.run(translations, locale: "sv", force: true)

  """

  alias GettextOps.{Config, Parser, Entry}
  alias Expo.Message

  @doc """
  Parse translation input in `msgid = msgstr` format.

  Accepts a string with one translation per line. Empty lines and lines
  starting with `#` are ignored. Lines that don't contain `=` are silently
  skipped.

  Returns `{:ok, translations_map}` where the map has msgid as keys and
  msgstr as values.

  ## Examples

      iex> input = \"\"\"
      ...> Sign In = Logga in
      ...> Sign Out = Logga ut
      ...> # This is a comment
      ...>
      ...> Welcome = Välkommen
      ...> \"\"\"
      iex> {:ok, translations} = GettextOps.Operations.Translate.parse_translations(input)
      iex> translations
      %{"Sign In" => "Logga in", "Sign Out" => "Logga ut", "Welcome" => "Välkommen"}

  """
  @spec parse_translations(String.t()) :: {:ok, %{String.t() => String.t()}}
  def parse_translations(input) when is_binary(input) do
    translations =
      input
      |> String.split("\n", trim: true)
      |> Enum.reject(&(String.starts_with?(&1, "#") or String.trim(&1) == ""))
      |> Enum.map(&parse_line/1)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    {:ok, translations}
  end

  # Parse a single line of translation input
  @spec parse_line(String.t()) :: {String.t(), String.t()} | nil
  defp parse_line(line) do
    case String.split(line, "=", parts: 2) do
      [msgid, msgstr] ->
        {String.trim(msgid), String.trim(msgstr)}

      _ ->
        nil
    end
  end

  @doc """
  Apply translations to a .po file.

  Takes a map of translations (msgid => msgstr) and updates the corresponding
  entries in the .po file for the given locale.

  ## Parameters

  - `translations` - Map of msgid => msgstr to apply
  - `opts` - Keyword list of options (see module documentation)

  ## Returns

  - `{:ok, result}` - Success with update statistics
  - `{:error, reason}` - Failure with error reason

  The result map contains:
  - `:updated` - Number of translations successfully applied
  - `:not_found` - List of msgids that were not found in the .po file

  ## Examples

      # Update translations
      translations = %{"Sign In" => "Logga in", "Sign Out" => "Logga ut"}
      {:ok, result} = GettextOps.Operations.Translate.run(translations, locale: "sv")
      # => {:ok, %{updated: 2, not_found: []}}

      # With missing msgid (without force)
      translations = %{"Nonexistent" => "Translation"}
      {:error, reason} = GettextOps.Operations.Translate.run(translations, locale: "sv")
      # => {:error, "msgid not found: Nonexistent"}

      # With missing msgid (with force)
      {:ok, result} = GettextOps.Operations.Translate.run(translations, locale: "sv", force: true)
      # => {:ok, %{updated: 0, not_found: ["Nonexistent"]}}

  """
  @spec run(map(), keyword()) ::
          {:ok, %{updated: non_neg_integer(), not_found: [String.t()]}} | {:error, term()}
  def run(translations, opts) when is_map(translations) do
    # Extract options
    locale = Keyword.fetch!(opts, :locale)
    domain = Keyword.get(opts, :domain)
    force = Keyword.get(opts, :force, false)

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
        do_translate(po_path, translations, force)
      end
    end
  end

  # Perform the actual translation update
  @spec do_translate(String.t(), map(), boolean()) ::
          {:ok, %{updated: non_neg_integer(), not_found: [String.t()]}} | {:error, term()}
  defp do_translate(po_path, translations, force) do
    # Parse the full .po file (we need the complete structure for Expo.PO.compose)
    case Parser.parse_file_full(po_path) do
      {:ok, %Expo.Messages{} = messages} ->
        # Apply translations and track results
        {updated_messages, stats} = apply_translations(messages.messages, translations)

        # Check if any msgids were not found
        if not force and length(stats.not_found) > 0 do
          {:error, "msgid not found: #{Enum.join(stats.not_found, ", ")}"}
        else
          # Create updated Messages struct
          updated = %{messages | messages: updated_messages}

          # Write atomically
          case write_po_file_atomic(po_path, updated) do
            :ok ->
              {:ok, stats}

            {:error, reason} ->
              {:error, reason}
          end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Apply translations to messages and track statistics
  @spec apply_translations([Message.t()], map()) ::
          {[Message.t()], %{updated: non_neg_integer(), not_found: [String.t()]}}
  defp apply_translations(messages, translations) do
    # Build a map of msgid => message for quick lookup
    message_map =
      messages
      |> Enum.map(fn msg -> {Entry.get_msgid(msg), msg} end)
      |> Map.new()

    # Apply each translation
    {updated_map, stats} =
      Enum.reduce(translations, {message_map, %{updated: 0, not_found: []}}, fn {msgid, msgstr},
                                                                                {acc_map,
                                                                                 acc_stats} ->
        case Map.get(acc_map, msgid) do
          nil ->
            # msgid not found
            {acc_map, %{acc_stats | not_found: [msgid | acc_stats.not_found]}}

          message ->
            # Update the message
            updated_message = Entry.update_msgstr(message, msgstr)
            updated_map = Map.put(acc_map, msgid, updated_message)
            {updated_map, %{acc_stats | updated: acc_stats.updated + 1}}
        end
      end)

    # Convert back to list, preserving order
    updated_messages =
      Enum.map(messages, fn msg ->
        msgid = Entry.get_msgid(msg)
        Map.get(updated_map, msgid, msg)
      end)

    # Reverse not_found list to preserve original order
    stats = %{stats | not_found: Enum.reverse(stats.not_found)}

    {updated_messages, stats}
  end

  # Write .po file atomically using a temporary file
  @spec write_po_file_atomic(String.t(), Expo.Messages.t()) :: :ok | {:error, term()}
  defp write_po_file_atomic(po_path, messages) do
    # Generate content using Expo.PO.compose
    content = Expo.PO.compose(messages)

    # Create temporary file in the same directory
    temp_path = po_path <> ".tmp"

    try do
      # Write to temp file
      File.write!(temp_path, content)

      # Atomically rename temp file to original
      File.rename!(temp_path, po_path)

      :ok
    rescue
      e ->
        # Clean up temp file if it exists
        File.rm(temp_path)
        {:error, Exception.message(e)}
    end
  end
end
