defmodule GettextOps.ConfigTest do
  use ExUnit.Case

  # Doctests demonstrate default behavior and should run with clean config
  # However, since other test modules may set config globally, we skip them here
  # and rely on the regular tests below to verify the actual behavior
  # doctest GettextOps.Config

  alias GettextOps.Config

  describe "gettext_path/0" do
    test "returns default path when not configured" do
      # Clear any existing config
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.delete_env(:gettext_ops, :gettext_path)

      assert Config.gettext_path() == "priv/gettext"

      # Restore original config
      if original, do: Application.put_env(:gettext_ops, :gettext_path, original)
    end

    test "returns configured path when set" do
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.put_env(:gettext_ops, :gettext_path, "custom/path")

      assert Config.gettext_path() == "custom/path"

      # Restore original config
      if original do
        Application.put_env(:gettext_ops, :gettext_path, original)
      else
        Application.delete_env(:gettext_ops, :gettext_path)
      end
    end
  end

  describe "default_domain/0" do
    test "returns default domain when not configured" do
      original = Application.get_env(:gettext_ops, :default_domain)
      Application.delete_env(:gettext_ops, :default_domain)

      assert Config.default_domain() == "default"

      if original, do: Application.put_env(:gettext_ops, :default_domain, original)
    end

    test "returns configured domain when set" do
      original = Application.get_env(:gettext_ops, :default_domain)
      Application.put_env(:gettext_ops, :default_domain, "errors")

      assert Config.default_domain() == "errors"

      if original do
        Application.put_env(:gettext_ops, :default_domain, original)
      else
        Application.delete_env(:gettext_ops, :default_domain)
      end
    end
  end

  describe "po_file_path/2" do
    test "resolves path with default domain" do
      # Clear any test-specific config
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.delete_env(:gettext_ops, :gettext_path)

      assert Config.po_file_path("sv") == "priv/gettext/sv/LC_MESSAGES/default.po"

      if original, do: Application.put_env(:gettext_ops, :gettext_path, original)
    end

    test "resolves path with custom domain" do
      # Clear any test-specific config
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.delete_env(:gettext_ops, :gettext_path)

      assert Config.po_file_path("sv", "errors") == "priv/gettext/sv/LC_MESSAGES/errors.po"

      if original, do: Application.put_env(:gettext_ops, :gettext_path, original)
    end

    test "resolves path for different locales" do
      # Clear any test-specific config
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.delete_env(:gettext_ops, :gettext_path)

      assert Config.po_file_path("en") == "priv/gettext/en/LC_MESSAGES/default.po"
      assert Config.po_file_path("fr") == "priv/gettext/fr/LC_MESSAGES/default.po"
      assert Config.po_file_path("de") == "priv/gettext/de/LC_MESSAGES/default.po"

      if original, do: Application.put_env(:gettext_ops, :gettext_path, original)
    end

    test "uses configured gettext_path" do
      original_path = Application.get_env(:gettext_ops, :gettext_path)
      Application.put_env(:gettext_ops, :gettext_path, "custom/gettext")

      assert Config.po_file_path("sv") == "custom/gettext/sv/LC_MESSAGES/default.po"

      if original_path do
        Application.put_env(:gettext_ops, :gettext_path, original_path)
      else
        Application.delete_env(:gettext_ops, :gettext_path)
      end
    end
  end

  describe "pot_file_path/1" do
    test "resolves template path with default domain" do
      # Clear any test-specific config
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.delete_env(:gettext_ops, :gettext_path)

      assert Config.pot_file_path() == "priv/gettext/default.pot"

      if original, do: Application.put_env(:gettext_ops, :gettext_path, original)
    end

    test "resolves template path with custom domain" do
      # Clear any test-specific config
      original = Application.get_env(:gettext_ops, :gettext_path)
      Application.delete_env(:gettext_ops, :gettext_path)

      assert Config.pot_file_path("errors") == "priv/gettext/errors.pot"

      if original, do: Application.put_env(:gettext_ops, :gettext_path, original)
    end

    test "uses configured gettext_path" do
      original_path = Application.get_env(:gettext_ops, :gettext_path)
      Application.put_env(:gettext_ops, :gettext_path, "custom/gettext")

      assert Config.pot_file_path() == "custom/gettext/default.pot"

      if original_path do
        Application.put_env(:gettext_ops, :gettext_path, original_path)
      else
        Application.delete_env(:gettext_ops, :gettext_path)
      end
    end
  end

  describe "list_po_files/0" do
    setup do
      # Set gettext_path to our test fixtures
      original_path = Application.get_env(:gettext_ops, :gettext_path)
      Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")

      on_exit(fn ->
        if original_path do
          Application.put_env(:gettext_ops, :gettext_path, original_path)
        else
          Application.delete_env(:gettext_ops, :gettext_path)
        end
      end)
    end

    test "lists all .po files in fixtures" do
      files = Config.list_po_files()

      assert length(files) == 2
      assert "test/fixtures/gettext/en/LC_MESSAGES/default.po" in files
      assert "test/fixtures/gettext/sv/LC_MESSAGES/default.po" in files
    end

    test "returns sorted list" do
      files = Config.list_po_files()
      assert files == Enum.sort(files)
    end

    test "returns empty list when gettext_path does not exist" do
      Application.put_env(:gettext_ops, :gettext_path, "nonexistent/path")

      assert Config.list_po_files() == []
    end
  end

  describe "list_locales/0" do
    setup do
      original_path = Application.get_env(:gettext_ops, :gettext_path)
      Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")

      on_exit(fn ->
        if original_path do
          Application.put_env(:gettext_ops, :gettext_path, original_path)
        else
          Application.delete_env(:gettext_ops, :gettext_path)
        end
      end)
    end

    test "lists all locale directories" do
      locales = Config.list_locales()

      assert length(locales) == 2
      assert "en" in locales
      assert "sv" in locales
    end

    test "returns sorted list" do
      locales = Config.list_locales()
      assert locales == Enum.sort(locales)
    end

    test "excludes files and hidden directories" do
      # The .pot file and any hidden directories should not be in the locale list
      locales = Config.list_locales()

      refute "default.pot" in locales
      refute Enum.any?(locales, &String.starts_with?(&1, "."))
    end

    test "returns empty list when gettext_path does not exist" do
      Application.put_env(:gettext_ops, :gettext_path, "nonexistent/path")

      assert Config.list_locales() == []
    end
  end

  describe "locale_exists?/1" do
    setup do
      original_path = Application.get_env(:gettext_ops, :gettext_path)
      Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")

      on_exit(fn ->
        if original_path do
          Application.put_env(:gettext_ops, :gettext_path, original_path)
        else
          Application.delete_env(:gettext_ops, :gettext_path)
        end
      end)
    end

    test "returns true for existing locales" do
      assert Config.locale_exists?("sv")
      assert Config.locale_exists?("en")
    end

    test "returns false for non-existing locales" do
      refute Config.locale_exists?("fr")
      refute Config.locale_exists?("de")
      refute Config.locale_exists?("nonexistent")
    end
  end
end
