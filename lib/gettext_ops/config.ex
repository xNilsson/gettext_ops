defmodule GettextOps.Config do
  @moduledoc """
  Configuration and path resolution for gettext_ops.

  This module provides functions to read configuration from the Application
  environment and resolve paths to .po and .pot files in Phoenix's gettext
  directory structure.

  ## Configuration

  Configure gettext_ops in your `config/config.exs`:

      config :gettext_ops,
        gettext_path: "priv/gettext",
        default_domain: "default"

  ## Path Structure

  gettext_ops follows Phoenix Gettext conventions:

  - `.po` files: `priv/gettext/{locale}/LC_MESSAGES/{domain}.po`
  - `.pot` template: `priv/gettext/{domain}.pot`

  ## Examples

      iex> GettextOps.Config.po_file_path("sv")
      "priv/gettext/sv/LC_MESSAGES/default.po"

      iex> GettextOps.Config.pot_file_path()
      "priv/gettext/default.pot"
  """

  @doc """
  Get the configured gettext path.

  Returns the path to the gettext directory. Defaults to `"priv/gettext"` if not configured.

  ## Examples

      iex> GettextOps.Config.gettext_path()
      "priv/gettext"
  """
  @spec gettext_path() :: String.t()
  def gettext_path do
    Application.get_env(:gettext_ops, :gettext_path, "priv/gettext")
  end

  @doc """
  Get the default domain name.

  Returns the default domain for .po files. Defaults to `"default"` if not configured.

  ## Examples

      iex> GettextOps.Config.default_domain()
      "default"
  """
  @spec default_domain() :: String.t()
  def default_domain do
    Application.get_env(:gettext_ops, :default_domain, "default")
  end

  @doc """
  Resolve the path to a locale's .po file.

  Returns the full path to a .po file for the given locale and domain.
  If domain is not provided, uses the configured default domain.

  ## Examples

      iex> GettextOps.Config.po_file_path("sv")
      "priv/gettext/sv/LC_MESSAGES/default.po"

      iex> GettextOps.Config.po_file_path("sv", "errors")
      "priv/gettext/sv/LC_MESSAGES/errors.po"
  """
  @spec po_file_path(locale :: String.t(), domain :: String.t() | nil) :: String.t()
  def po_file_path(locale, domain \\ nil) do
    domain = domain || default_domain()
    Path.join([gettext_path(), locale, "LC_MESSAGES", "#{domain}.po"])
  end

  @doc """
  Find the path to a .pot template file.

  Returns the path to the .pot template file for the given domain.
  If domain is not provided, uses the configured default domain.

  Note: This returns the path regardless of whether the file exists.
  Use `File.exists?/1` to check if the template file is present.

  ## Examples

      iex> GettextOps.Config.pot_file_path()
      "priv/gettext/default.pot"

      iex> GettextOps.Config.pot_file_path("errors")
      "priv/gettext/errors.pot"
  """
  @spec pot_file_path(domain :: String.t() | nil) :: String.t()
  def pot_file_path(domain \\ nil) do
    domain = domain || default_domain()
    Path.join([gettext_path(), "#{domain}.pot"])
  end

  @doc """
  List all available .po files.

  Recursively scans the gettext directory and returns paths to all .po files found.
  Returns an empty list if the gettext directory doesn't exist.
  """
  @spec list_po_files() :: [String.t()]
  def list_po_files do
    gettext_path()
    |> Path.join("**/*.po")
    |> Path.wildcard()
    |> Enum.sort()
  end

  @doc """
  List all available locales.

  Scans the gettext directory structure and returns a list of all locale
  codes found (directory names directly under the gettext path).
  Returns an empty list if the gettext directory doesn't exist.
  """
  @spec list_locales() :: [String.t()]
  def list_locales do
    path = gettext_path()

    if File.exists?(path) do
      path
      |> File.ls!()
      |> Enum.filter(fn name ->
        locale_path = Path.join(path, name)
        File.dir?(locale_path) and not String.starts_with?(name, ".")
      end)
      |> Enum.sort()
    else
      []
    end
  end

  @doc """
  Check if a .po file exists for the given locale.

  Returns `true` if the locale directory exists under the configured
  gettext path, `false` otherwise.
  """
  @spec locale_exists?(locale :: String.t()) :: boolean()
  def locale_exists?(locale) do
    locale in list_locales()
  end
end
