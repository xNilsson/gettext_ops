defmodule Mix.Tasks.GettextOps.ChangeMsgid do
  use Mix.Task

  @shortdoc "Change msgid across all locale files"

  @moduledoc """
  Update msgid (source text) across all .po and .pot files.

  This command updates the msgid field in all translation files while preserving
  all existing translations (msgstr values remain intact). It's useful for fixing
  typos, improving wording, or standardizing terminology in your source strings.

  ## Usage

      mix gettext_ops.change_msgid OLD_MSGID NEW_MSGID [options]

  ## What It Does

  1. Finds all .po files in priv/gettext/*/LC_MESSAGES/ for the specified domain
  2. Finds the .pot template file for the specified domain
  3. Updates the msgid in all matching entries
  4. **Preserves all translations** (msgstr values remain intact)
  5. Shows summary of changes

  ## Arguments

  - `OLD_MSGID` - The current msgid to find and replace
  - `NEW_MSGID` - The new msgid to use

  ## Options

  - `--dry-run` - Preview changes without modifying files
  - `--domain` / `-d` - Gettext domain (defaults to configured default_domain)

  ## Examples

      # Update msgid everywhere
      mix gettext_ops.change_msgid "Sign In" "Log In"

      # Preview changes first (recommended)
      mix gettext_ops.change_msgid --dry-run "Sign In" "Log In"

      # Specific domain
      mix gettext_ops.change_msgid "Error" "Warning" --domain errors

  ## Dry Run Output Example

      Would update the following files:

      ✓ priv/gettext/sv/LC_MESSAGES/default.po (1 entry)
        msgid "Sign In" → "Log In"
        msgstr "Logga in" (preserved)

      ✓ priv/gettext/en/LC_MESSAGES/default.po (1 entry)
        msgid "Sign In" → "Log In"
        msgstr "" (preserved)

      ✓ priv/gettext/default.pot (1 entry)
        msgid "Sign In" → "Log In"

      Would update 3 file(s) with 3 total entries

  ## Actual Update Output

      Updated the following files:

      ✓ priv/gettext/sv/LC_MESSAGES/default.po (1 entry)
      ✓ priv/gettext/en/LC_MESSAGES/default.po (1 entry)
      ✓ priv/gettext/default.pot (1 entry)

      Updated 3 file(s) with 3 total entries

  ## Safety Features

  - **Atomic updates**: Files are written atomically to prevent corruption
  - **Dry run mode**: Always preview changes with `--dry-run` before applying
  - **Preserves translations**: All msgstr values remain unchanged
  - **Preserves metadata**: Comments, references, and flags are retained

  ## Important Notes

  - This command does NOT update source code references
  - After changing msgid, you may need to update your source code separately
  - Use `--dry-run` first to verify which files will be affected
  - All translations (msgstr) are preserved automatically

  """

  alias GettextOps.Operations.ChangeMsgid

  @switches [
    dry_run: :boolean,
    domain: :string
  ]

  @aliases [
    d: :domain
  ]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    # Check for invalid options
    if invalid != [] do
      Mix.shell().error("Invalid options: #{inspect(invalid)}")
      Mix.shell().info(get_usage())
      exit({:shutdown, 1})
    end

    # Validate we have exactly 2 arguments
    case argv do
      [old_msgid, new_msgid] ->
        # Execute the change
        case ChangeMsgid.run(old_msgid, new_msgid, opts) do
          {:ok, result} ->
            print_result(result, old_msgid, new_msgid, opts[:dry_run] || false)
            :ok

          {:error, reason} ->
            Mix.shell().error("Error: #{reason}")
            exit({:shutdown, 1})
        end

      [] ->
        Mix.shell().error("Error: OLD_MSGID and NEW_MSGID arguments are required")
        Mix.shell().info(get_usage())
        exit({:shutdown, 1})

      [_] ->
        Mix.shell().error("Error: NEW_MSGID argument is required")
        Mix.shell().info(get_usage())
        exit({:shutdown, 1})

      _ ->
        Mix.shell().error("Error: Too many arguments provided")
        Mix.shell().info(get_usage())
        exit({:shutdown, 1})
    end
  end

  # Print the result summary
  @spec print_result(
          %{
            files_updated: non_neg_integer(),
            entries_updated: non_neg_integer(),
            changes: [map()]
          },
          String.t(),
          String.t(),
          boolean()
        ) :: :ok
  defp print_result(
         %{files_updated: files_updated, entries_updated: entries_updated, changes: changes},
         old_msgid,
         new_msgid,
         dry_run
       ) do
    if entries_updated == 0 do
      Mix.shell().info("No matching entries found for msgid: \"#{old_msgid}\"")
    else
      if dry_run do
        Mix.shell().info("Would update the following files:\n")
      else
        Mix.shell().info("Updated the following files:\n")
      end

      # Print each change
      Enum.each(changes, fn %{file: file, entries: count, sample_msgstr: msgstr} ->
        Mix.shell().info("✓ #{file} (#{count} #{pluralize("entry", count)})")

        # Only show detailed preview for dry_run
        if dry_run do
          Mix.shell().info("  msgid \"#{old_msgid}\" → \"#{new_msgid}\"")

          # Show msgstr if available (empty for .pot files)
          if msgstr != "" do
            Mix.shell().info("  msgstr \"#{msgstr}\" (preserved)")
          end
        end
      end)

      Mix.shell().info("")

      if dry_run do
        Mix.shell().info(
          "Would update #{files_updated} #{pluralize("file", files_updated)} with #{entries_updated} total #{pluralize("entry", entries_updated)}"
        )
      else
        Mix.shell().info(
          "Updated #{files_updated} #{pluralize("file", files_updated)} with #{entries_updated} total #{pluralize("entry", entries_updated)}"
        )
      end
    end

    :ok
  end

  # Simple pluralization helper
  @spec pluralize(String.t(), non_neg_integer()) :: String.t()
  defp pluralize(word, 1), do: word
  defp pluralize(word, _), do: "#{word}s"

  defp get_usage do
    """
    Usage: mix gettext_ops.change_msgid OLD_MSGID NEW_MSGID [options]

    Arguments:
      OLD_MSGID       The current msgid to find and replace
      NEW_MSGID       The new msgid to use

    Options:
      --dry-run       Preview changes without modifying files
      --domain, -d    Gettext domain (optional)

    Examples:
      # Preview changes first (recommended)
      mix gettext_ops.change_msgid --dry-run "Sign In" "Log In"

      # Update msgid everywhere
      mix gettext_ops.change_msgid "Sign In" "Log In"

      # Specific domain
      mix gettext_ops.change_msgid "Error" "Warning" --domain errors
    """
  end
end
