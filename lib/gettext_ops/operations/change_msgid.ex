defmodule GettextOps.Operations.ChangeMsgid do
  @moduledoc """
  Change msgid operation for updating source text across all .po and .pot files.

  This module provides functionality to update msgid (source text) across all
  locale .po files and .pot template files while preserving existing translations.

  **Important:** This operation updates the source text (msgid) but keeps all
  translations (msgstr) intact. It updates:
  - All locale .po files (e.g., priv/gettext/sv/LC_MESSAGES/default.po)
  - The .pot template file (e.g., priv/gettext/default.pot)

  ## Use Cases

  This command is useful when you need to:
  - Fix typos in source strings
  - Improve wording of UI text
  - Standardize terminology
  - Refactor text keys

  ## Atomic Updates

  Updates are performed atomically by writing to a temporary file and then
  renaming it to the original file. This prevents corruption if the operation
  fails midway.

  ## Options

  - `:domain` - The domain to update (defaults to configured default_domain)
  - `:dry_run` - Preview changes without modifying files (default: false)

  ## Examples

      # Update msgid across all files
      {:ok, result} = GettextOps.Operations.ChangeMsgid.run("Sign In", "Log In")
      # => {:ok, %{files_updated: 3, entries_updated: 3, changes: [...]}}

      # Preview changes first (dry run)
      {:ok, result} = GettextOps.Operations.ChangeMsgid.run("Sign In", "Log In", dry_run: true)
      # => {:ok, %{files_updated: 0, entries_updated: 0, changes: [...]}}

      # Specific domain
      {:ok, result} = GettextOps.Operations.ChangeMsgid.run("Error", "Warning", domain: "errors")

  """

  alias GettextOps.{Config, Parser, Entry}
  alias Expo.Message

  @doc """
  Change msgid across all translation files.

  Takes an old msgid and new msgid, then updates all matching entries across
  all .po files and the .pot template file. Preserves all translations (msgstr).

  ## Parameters

  - `old_msgid` - The current msgid to find and replace
  - `new_msgid` - The new msgid to use
  - `opts` - Keyword list of options:
    - `:domain` - The domain to update (default: configured default_domain)
    - `:dry_run` - If true, don't write files, just return what would change (default: false)

  ## Returns

  - `{:ok, result}` - Success with change statistics
  - `{:error, reason}` - Failure with error reason

  The result map contains:
  - `:files_updated` - Number of files actually updated (0 for dry_run)
  - `:entries_updated` - Total number of entries that would be/were updated
  - `:changes` - List of file change details

  ## Examples

      # Update msgid everywhere
      {:ok, result} = GettextOps.Operations.ChangeMsgid.run("Sign In", "Log In")
      # => {:ok, %{files_updated: 3, entries_updated: 3, changes: [...]}}

      # Dry run to preview
      {:ok, result} = GettextOps.Operations.ChangeMsgid.run("Sign In", "Log In", dry_run: true)
      # => {:ok, %{files_updated: 0, entries_updated: 3, changes: [...]}}

  """
  @spec run(String.t(), String.t(), keyword()) ::
          {:ok,
           %{
             files_updated: non_neg_integer(),
             entries_updated: non_neg_integer(),
             changes: [map()]
           }}
          | {:error, term()}
  def run(old_msgid, new_msgid, opts \\ []) when is_binary(old_msgid) and is_binary(new_msgid) do
    # Validate that old and new are different
    if old_msgid == new_msgid do
      {:error, "old_msgid and new_msgid must be different"}
    else
      domain = Keyword.get(opts, :domain)
      dry_run = Keyword.get(opts, :dry_run, false)

      # Collect all files to update (.po files + .pot file)
      po_files = Config.list_po_files()
      pot_file = Config.pot_file_path(domain)

      # Filter .po files by domain if specified
      po_files_to_update =
        if domain do
          domain_name = domain || Config.default_domain()

          Enum.filter(po_files, fn path ->
            String.contains?(path, "/#{domain_name}.po")
          end)
        else
          # If no domain specified, only update files in the default domain
          domain_name = Config.default_domain()

          Enum.filter(po_files, fn path ->
            String.contains?(path, "/#{domain_name}.po")
          end)
        end

      # Add .pot file if it exists
      all_files =
        if File.exists?(pot_file) do
          po_files_to_update ++ [pot_file]
        else
          po_files_to_update
        end

      # Process each file
      results =
        Enum.map(all_files, fn file_path ->
          case update_file(file_path, old_msgid, new_msgid, dry_run) do
            {:ok, count, sample_msgstr} ->
              {:ok, %{file: file_path, entries: count, sample_msgstr: sample_msgstr}}

            {:error, reason} ->
              {:error, %{file: file_path, reason: reason}}
          end
        end)

      # Separate successes and failures
      {successes, failures} =
        Enum.split_with(results, fn
          {:ok, _} -> true
          {:error, _} -> false
        end)

      # If any failures, return first error
      case failures do
        [{:error, error} | _] ->
          {:error, error}

        [] ->
          # Extract change details
          changes =
            Enum.map(successes, fn {:ok, change} -> change end)
            |> Enum.filter(fn %{entries: count} -> count > 0 end)

          total_entries = Enum.sum(Enum.map(changes, fn %{entries: count} -> count end))
          files_updated = if dry_run, do: 0, else: length(changes)

          {:ok,
           %{
             files_updated: files_updated,
             entries_updated: total_entries,
             changes: changes
           }}
      end
    end
  end

  @doc """
  Update msgid in a single file.

  Reads the file, finds all messages matching old_msgid, updates them to new_msgid,
  and writes the file back (unless dry_run is true).

  ## Parameters

  - `file_path` - Path to the .po or .pot file
  - `old_msgid` - The msgid to find and replace
  - `new_msgid` - The new msgid value
  - `dry_run` - If true, don't write the file

  ## Returns

  - `{:ok, count, sample_msgstr}` - Success with number of entries updated and a sample msgstr
  - `{:error, reason}` - Failure with error reason

  ## Examples

      # Update a single file
      {:ok, count, msgstr} = GettextOps.Operations.ChangeMsgid.update_file(
        "priv/gettext/sv/LC_MESSAGES/default.po",
        "Sign In",
        "Log In",
        false
      )
      # => {:ok, 1, "Logga in"}

  """
  @spec update_file(String.t(), String.t(), String.t(), boolean()) ::
          {:ok, non_neg_integer(), String.t()} | {:error, term()}
  def update_file(file_path, old_msgid, new_msgid, dry_run \\ false)
      when is_binary(file_path) and is_binary(old_msgid) and is_binary(new_msgid) and
             is_boolean(dry_run) do
    # Parse the full .po/.pot file
    case Parser.parse_file_full(file_path) do
      {:ok, %Expo.Messages{} = messages} ->
        # Update messages that match old_msgid
        {updated_messages, count, sample_msgstr} =
          update_messages(messages.messages, old_msgid, new_msgid)

        # Only write if not dry_run and we actually updated something
        if dry_run or count == 0 do
          {:ok, count, sample_msgstr}
        else
          # Create updated Messages struct
          updated = %{messages | messages: updated_messages}

          # Write atomically
          case write_po_file_atomic(file_path, updated) do
            :ok ->
              {:ok, count, sample_msgstr}

            {:error, reason} ->
              {:error, reason}
          end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Update messages that match old_msgid, return {updated_messages, count, sample_msgstr}
  @spec update_messages([Message.t()], String.t(), String.t()) ::
          {[Message.t()], non_neg_integer(), String.t()}
  defp update_messages(messages, old_msgid, new_msgid) do
    {updated_messages, count, sample_msgstr} =
      Enum.reduce(messages, {[], 0, ""}, fn msg, {acc_messages, acc_count, acc_sample} ->
        if Entry.matches_msgid?(msg, old_msgid) do
          updated_msg = Entry.update_msgid(msg, new_msgid)
          # Capture a sample msgstr for reporting (from first match)
          sample = if acc_count == 0, do: Entry.get_msgstr(msg), else: acc_sample
          {[updated_msg | acc_messages], acc_count + 1, sample}
        else
          {[msg | acc_messages], acc_count, acc_sample}
        end
      end)

    # Reverse to maintain original order
    {Enum.reverse(updated_messages), count, sample_msgstr}
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
