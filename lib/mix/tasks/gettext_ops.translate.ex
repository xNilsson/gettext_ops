defmodule Mix.Tasks.GettextOps.Translate do
  use Mix.Task

  @shortdoc "Apply translations from stdin or file"

  @moduledoc """
  Update msgstr (translations) in .po files from various input sources.

  This is the **most important command** for the LLM workflow. It enables
  bulk translation updates without manually editing .po files. Accepts
  translations in a simple format: `msgid = msgstr` (one per line).

  ## Usage

      mix gettext_ops.translate [options]

  ## Input Sources

  The task accepts translation input from multiple sources:

  1. **stdin (most common for LLM workflows)**

      ```bash
      mix gettext_ops.translate --locale sv <<EOF
      Sign In = Logga in
      Sign Out = Logga ut
      EOF
      ```

  2. **File**

      ```bash
      mix gettext_ops.translate --locale sv --file translations.txt
      ```

  3. **Pipe**

      ```bash
      echo "Welcome = Välkommen" | mix gettext_ops.translate --locale sv
      ```

  ## Input Format

  Each line should contain a msgid and msgstr separated by `=`:

      Sign In = Logga in
      Sign Out = Logga ut
      Welcome = Välkommen
      Error: Invalid input = Fel: Ogiltig inmatning

  Empty lines and lines starting with `#` (comments) are ignored.

  ## Options

  - `--locale` / `-l` - (required) Target locale (e.g., "sv", "en")
  - `--domain` / `-d` - Gettext domain (defaults to configured default_domain)
  - `--file` / `-f` - Input file (uses stdin if not provided)
  - `--force` - Continue even if some msgids are not found (show warnings instead of failing)

  ## Examples

      # From stdin (heredoc) - most common
      mix gettext_ops.translate --locale sv <<EOF
      Sign In = Logga in
      Sign Out = Logga ut
      EOF

      # From file
      mix gettext_ops.translate --locale sv --file translations.txt

      # From pipe
      echo "Welcome = Välkommen" | mix gettext_ops.translate --locale sv

      # With force flag (ignore missing msgids)
      mix gettext_ops.translate --locale sv --force --file partial.txt

      # LLM workflow example
      mix gettext_ops.list_untranslated --locale sv --json --limit 10 | \\
        llm "translate to Swedish" | \\
        mix gettext_ops.translate --locale sv

  ## Atomic Updates

  Updates are performed atomically by writing to a temporary file and then
  renaming it. This ensures the .po file is never left in a corrupted state.

  ## Error Handling

  By default, the command fails if any msgid is not found in the .po file.
  Use `--force` to continue with partial updates and get warnings instead.

  """

  alias GettextOps.Operations.Translate

  @switches [
    locale: :string,
    domain: :string,
    file: :string,
    force: :boolean
  ]

  @aliases [
    l: :locale,
    d: :domain,
    f: :file
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    # Check for invalid options
    if invalid != [] do
      Mix.shell().error("Invalid options: #{inspect(invalid)}")
      Mix.shell().info(get_usage())
      exit({:shutdown, 1})
    end

    # Validate required arguments
    unless opts[:locale] do
      Mix.shell().error("Error: --locale option is required")
      Mix.shell().info(get_usage())
      exit({:shutdown, 1})
    end

    # Read input (from file or stdin)
    input =
      case opts[:file] do
        nil ->
          # Read from stdin
          read_stdin()

        file_path ->
          # Read from file
          case File.read(file_path) do
            {:ok, content} ->
              content

            {:error, reason} ->
              Mix.shell().error("Error reading file: #{:file.format_error(reason)}")
              exit({:shutdown, 1})
          end
      end

    # Parse translations
    {:ok, translations} = Translate.parse_translations(input)

    # Check if we have any translations
    if map_size(translations) == 0 do
      Mix.shell().error("Error: No valid translations found in input")
      exit({:shutdown, 1})
    end

    # Apply translations
    case Translate.run(translations, opts) do
      {:ok, result} ->
        # Print success message
        print_result(result, opts[:force] || false)
        :ok

      {:error, reason} ->
        Mix.shell().error("Error: #{reason}")
        exit({:shutdown, 1})
    end
  end

  # Read from stdin until EOF
  @spec read_stdin() :: String.t()
  defp read_stdin do
    IO.stream(:stdio, :line)
    |> Enum.to_list()
    |> IO.iodata_to_binary()
  end

  # Print the result summary
  @spec print_result(%{updated: non_neg_integer(), not_found: [String.t()]}, boolean()) :: :ok
  defp print_result(%{updated: updated, not_found: not_found}, force) do
    # Print success message
    Mix.shell().info("✓ Updated #{updated} translation(s)")

    # Print warnings if any msgids were not found
    if length(not_found) > 0 do
      if force do
        Mix.shell().info("\nWarnings (#{length(not_found)} msgid(s) not found):")
      else
        Mix.shell().info("\nNot found (#{length(not_found)} msgid(s)):")
      end

      Enum.each(not_found, fn msgid ->
        Mix.shell().info("  - #{msgid}")
      end)
    end

    :ok
  end

  defp get_usage do
    """
    Usage: mix gettext_ops.translate --locale LOCALE [options]

    Options:
      --locale, -l    Target locale (required)
      --domain, -d    Gettext domain (optional)
      --file, -f      Input file (uses stdin if not provided)
      --force         Continue even if msgid not found

    Examples:
      mix gettext_ops.translate --locale sv <<EOF
      Sign In = Logga in
      Sign Out = Logga ut
      EOF

      mix gettext_ops.translate --locale sv --file translations.txt
      echo "Welcome = Välkommen" | mix gettext_ops.translate --locale sv
    """
  end
end
