defmodule Mix.Tasks.GettextOps.SearchValue do
  @shortdoc "Search for entries by msgstr (translated text)"

  @moduledoc """
  Search for translation entries by msgstr (translated text) in .po files.

  ## Usage

      mix gettext_ops.search_value PATTERN [options]

  ## Arguments

  - `PATTERN` - The search pattern (substring or regex)

  ## Options

  - `--locale` - (required) Locale to search in (e.g., "sv", "en")
  - `--domain` - Domain to search in (defaults to configured default_domain)
  - `--regex` - Treat pattern as regex instead of substring
  - `--limit` - Maximum number of results to return
  - `--json` - Output in JSON format (line-delimited)

  ## Examples

      # Substring search (case-insensitive)
      mix gettext_ops.search_value "Välkommen" --locale sv

      # Regex search for translations starting with "Fel"
      mix gettext_ops.search_value "^Fel" --locale sv --regex

      # JSON output with limit
      mix gettext_ops.search_value "knapp" --locale sv --json --limit 5

  """

  use Mix.Task

  alias GettextOps.Operations.SearchValue
  alias GettextOps.Output

  @switches [
    locale: :string,
    domain: :string,
    regex: :boolean,
    limit: :integer,
    json: :boolean
  ]

  @aliases [
    l: :locale,
    d: :domain,
    r: :regex,
    n: :limit,
    j: :json
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

    # Get pattern from argv
    pattern =
      case argv do
        [pattern | _] -> pattern
        [] -> nil
      end

    # Validate required arguments
    unless pattern do
      Mix.shell().error("Error: PATTERN argument is required")
      Mix.shell().info(get_usage())
      exit({:shutdown, 1})
    end

    unless opts[:locale] do
      Mix.shell().error("Error: --locale option is required")
      Mix.shell().info(get_usage())
      exit({:shutdown, 1})
    end

    # Run the search
    case SearchValue.run(pattern, opts) do
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
    Usage: mix gettext_ops.search_value PATTERN --locale LOCALE [options]

    Options:
      --locale, -l    Locale to search in (required)
      --domain, -d    Domain to search in (optional)
      --regex, -r     Treat pattern as regex
      --limit, -n     Maximum number of results
      --json, -j      Output in JSON format

    Examples:
      mix gettext_ops.search_value "Välkommen" --locale sv
      mix gettext_ops.search_value "^Fel" --locale sv --regex
      mix gettext_ops.search_value "knapp" --locale sv --json --limit 5
    """
  end
end
