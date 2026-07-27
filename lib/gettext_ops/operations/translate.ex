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

  ## Entries with a msgctxt

  Gettext identifies an entry by the pair `{msgctxt, msgid}`, so a catalogue may
  hold several entries with the same msgid under different contexts. The input
  format carries only a msgid, which is resolved as follows:

  - exactly one entry has that msgid — it is updated;
  - several do — the **contextless** entry is updated, and context-carrying
    siblings are left untouched;
  - the msgid exists *only* under two or more contexts — it cannot be resolved,
    and is reported in `:ambiguous` rather than guessed at.

  ## Atomic Updates

  Updates are performed atomically by writing to a temporary file and then
  renaming it to the original file. This prevents corruption if the operation
  fails midway.

  ## Options

  - `:locale` - (required) The locale to update (e.g., "sv", "en")
  - `:domain` - The domain to update (defaults to configured default_domain)
  - `:force` - Continue even if some msgids are not found or ambiguous (default: false)

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

  alias GettextOps.{Config, Parser, Entry, Writer}
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
  - `:ambiguous` - List of `{msgid, contexts}` for msgids that exist only under
    two or more different `msgctxt` values and so could not be resolved

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
          {:ok,
           %{
             updated: non_neg_integer(),
             not_found: [String.t()],
             ambiguous: [{String.t(), [String.t()]}]
           }}
          | {:error, term()}
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
          {:ok,
           %{
             updated: non_neg_integer(),
             not_found: [String.t()],
             ambiguous: [{String.t(), [String.t()]}]
           }}
          | {:error, term()}
  defp do_translate(po_path, translations, force) do
    # Parse the full .po file (we need the complete structure for Expo.PO.compose)
    case Parser.parse_file_full(po_path) do
      {:ok, %Expo.Messages{} = messages} ->
        # Apply translations and track results
        {updated_messages, stats} = apply_translations(messages.messages, translations)

        cond do
          # Check if any msgids were not found
          not force and stats.not_found != [] ->
            {:error, "msgid not found: #{Enum.join(stats.not_found, ", ")}"}

          # Check if any msgids exist only under a msgctxt we cannot choose between
          not force and stats.ambiguous != [] ->
            {:error, ambiguous_error(stats.ambiguous)}

          true ->
            # Never write a catalogue that could not be read back
            with :ok <- Writer.check_duplicates(updated_messages),
                 updated = %{messages | messages: updated_messages},
                 :ok <- write_po_file_atomic(po_path, updated) do
              {:ok, stats}
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Apply translations to messages and track statistics
  @spec apply_translations([Message.t()], map()) ::
          {[Message.t()],
           %{
             updated: non_neg_integer(),
             not_found: [String.t()],
             ambiguous: [{String.t(), [String.t()]}]
           }}
  defp apply_translations(messages, translations) do
    # Translation input carries a bare msgid, but a catalogue entry is
    # identified by {msgctxt, msgid}. Group candidates by msgid so each
    # translation can be resolved to exactly one entry.
    candidates_by_msgid = Enum.group_by(messages, &Entry.get_msgid/1)

    empty_stats = %{updated: 0, not_found: [], ambiguous: []}

    # Collect only the entries a translation actually resolved to, keyed by
    # their full identity.
    {replacements, stats} =
      Enum.reduce(translations, {%{}, empty_stats}, fn {msgid, msgstr}, {acc_map, acc_stats} ->
        case resolve_target(Map.get(candidates_by_msgid, msgid, [])) do
          {:ok, message} ->
            acc_map = Map.put(acc_map, Entry.key(message), Entry.update_msgstr(message, msgstr))
            {acc_map, %{acc_stats | updated: acc_stats.updated + 1}}

          :not_found ->
            {acc_map, %{acc_stats | not_found: [msgid | acc_stats.not_found]}}

          {:ambiguous, contexts} ->
            {acc_map, %{acc_stats | ambiguous: [{msgid, contexts} | acc_stats.ambiguous]}}
        end
      end)

    # Rebuild in place: every message that no translation resolved to is
    # carried through untouched.
    updated_messages =
      Enum.map(messages, fn msg -> Map.get(replacements, Entry.key(msg), msg) end)

    # Reverse accumulated lists to preserve original input order
    stats = %{
      stats
      | not_found: Enum.reverse(stats.not_found),
        ambiguous: Enum.reverse(stats.ambiguous)
    }

    {updated_messages, stats}
  end

  # Pick the single entry a bare msgid refers to.
  #
  # With several candidates the contextless entry wins, since a translation
  # given without a context is the contextless one. A msgid that exists *only*
  # under two or more different msgctxt values cannot be resolved and is
  # reported rather than guessed at.
  @spec resolve_target([Message.t()]) ::
          {:ok, Message.t()} | :not_found | {:ambiguous, [String.t()]}
  defp resolve_target([]), do: :not_found
  defp resolve_target([message]), do: {:ok, message}

  defp resolve_target(candidates) do
    case Enum.filter(candidates, &is_nil(Entry.get_msgctxt(&1))) do
      [message] ->
        {:ok, message}

      _ ->
        contexts =
          candidates
          |> Enum.map(&Entry.get_msgctxt/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.sort()

        {:ambiguous, contexts}
    end
  end

  # Build the error message for msgids that exist only under several contexts
  @spec ambiguous_error([{String.t(), [String.t()]}]) :: String.t()
  defp ambiguous_error(ambiguous) do
    details =
      Enum.map_join(ambiguous, "; ", fn {msgid, contexts} ->
        quoted_contexts = Enum.map_join(contexts, ", ", fn context -> ~s("#{context}") end)
        ~s("#{msgid}") <> " (msgctxt: " <> quoted_contexts <> ")"
      end)

    "ambiguous msgid, exists only with a msgctxt: #{details}"
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
