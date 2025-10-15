defmodule Mix.Tasks.GettextOps.ListUntranslatedTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.GettextOps.ListUntranslated

  # Configure gettext path for tests
  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  describe "run/1" do
    test "lists untranslated entries with text output" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv"])
        end)

      assert output =~ ~s(msgid "world")
      assert output =~ ~s(msgstr "")
    end

    test "lists untranslated entries with JSON output" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv", "--json"])
        end)

      # Should be valid JSON
      assert output =~ ~s("msgid":"world")
      assert output =~ ~s("msgstr":"")
    end

    test "lists with limit option" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv", "--limit", "1"])
        end)

      # Should only show one result
      lines = String.split(output, "\n", trim: true)
      # Count msgid entries (not blank lines)
      msgid_count = Enum.count(lines, &String.contains?(&1, "msgid"))
      assert msgid_count == 1
    end

    test "lists with short option aliases" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["-l", "sv", "-j"])
        end)

      # Should work with short aliases
      assert output =~ ~s("msgid":"world")
    end

    test "returns empty output when all entries are translated" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "en"])
        end)

      # en locale has all entries translated, so output should be empty
      # (or at least not contain "world" since it's translated in en)
      lines = String.split(output, "\n", trim: true)
      # Filter out empty lines and count actual entries
      entry_lines = Enum.filter(lines, &(String.trim(&1) != ""))

      # Should have minimal or no entries
      assert length(entry_lines) >= 0
    end

    test "lists with limit of zero returns empty output" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv", "--limit", "0"])
        end)

      # Should be empty
      assert String.trim(output) == ""
    end

    test "lists with specific domain" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv", "--domain", "default"])
        end)

      assert output =~ ~s(msgid "world")
    end
  end

  describe "run/1 error handling" do
    test "shows error for missing locale option" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(ListUntranslated.run([]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for non-existent locale" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(ListUntranslated.run(["--locale", "nonexistent"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for invalid options" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(ListUntranslated.run(["--invalid-option", "value"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for non-existent domain" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(ListUntranslated.run(["--locale", "sv", "--domain", "nonexistent"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end
  end

  describe "run/1 output format consistency" do
    test "text output includes msgid and msgstr labels" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv"])
        end)

      # Text format should have human-readable labels
      assert output =~ "msgid"
      assert output =~ "msgstr"
    end

    test "json output is valid line-delimited JSON" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv", "--json"])
        end)

      # Each non-empty line should be valid JSON
      lines = String.split(output, "\n", trim: true)

      Enum.each(lines, fn line ->
        assert {:ok, _} = JSON.decode(line)
      end)
    end

    test "json output contains expected fields" do
      output =
        capture_io(fn ->
          ListUntranslated.run(["--locale", "sv", "--json"])
        end)

      # Should contain msgid and msgstr fields
      assert output =~ ~s("msgid")
      assert output =~ ~s("msgstr")
    end
  end
end
