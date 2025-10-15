defmodule Mix.Tasks.GettextOps.ListUntranslated do
  @shortdoc "List untranslated entries (empty msgstr)"

  @moduledoc """
  List all entries with empty translations in .po files.

  This is one of the most frequently used commands for developers and LLMs.
  It shows what needs translation without loading entire .po files, making
  it extremely token-efficient for AI agent workflows.

  ## Usage

      mix gettext_ops.list_untranslated [options]

  ## Options

  - `--locale` - (required) Locale to list untranslated entries from (e.g., "sv", "en")
  - `--domain` - Domain to search in (defaults to configured default_domain)
  - `--limit` - Maximum number of results to return (useful for LLMs)
  - `--json` - Output in JSON format (line-delimited)

  ## Examples

      # List all untranslated Swedish entries
      mix gettext_ops.list_untranslated --locale sv

      # Get first 10 as JSON (perfect for LLMs)
      mix gettext_ops.list_untranslated --locale sv --json --limit 10

      # Count untranslated entries
      mix gettext_ops.list_untranslated --locale sv | grep "msgid" | wc -l

      # Save to file for translation
      mix gettext_ops.list_untranslated --locale sv --json --limit 20 > to_translate.json

  ## Token Efficiency

  Instead of reading a 5000-line .po file (~15k tokens), this command
  returns only the untranslated entries (e.g., 10 entries ~500 tokens),
  making it ideal for LLM workflows.

  """

  use Mix.Task

  alias GettextOps.Operations.ListUntranslated
  alias GettextOps.Output

  @switches [
    locale: :string,
    domain: :string,
    limit: :integer,
    json: :boolean
  ]

  @aliases [
    l: :locale,
    d: :domain,
    n: :limit,
    j: :json
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

    # Run the list operation
    case ListUntranslated.run(opts) do
      {:ok, messages} ->
        # Determine output format
        format = if opts[:json], do: :json, else: :text

        # Print results
        Output.print_messages(messages, format)

        # Exit with success
        :ok

      {:error, reason} ->
        Mix.shell().error("Error: #{reason}")
        exit({:shutdown, 1})
    end
  end

  defp get_usage do
    """
    Usage: mix gettext_ops.list_untranslated --locale LOCALE [options]

    Options:
      --locale, -l    Locale to list untranslated entries from (required)
      --domain, -d    Domain to search in (optional)
      --limit, -n     Maximum number of results
      --json, -j      Output in JSON format

    Examples:
      mix gettext_ops.list_untranslated --locale sv
      mix gettext_ops.list_untranslated --locale sv --json --limit 10
      mix gettext_ops.list_untranslated --locale sv --domain errors
    """
  end
end
