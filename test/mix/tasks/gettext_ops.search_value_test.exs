defmodule Mix.Tasks.GettextOps.SearchValueTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.GettextOps.SearchValue

  # Configure gettext path for tests
  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  describe "run/1" do
    test "searches for entries by msgstr with text output" do
      output =
        capture_io(fn ->
          SearchValue.run(["hej", "--locale", "sv"])
        end)

      assert output =~ ~s(msgid "hello")
      assert output =~ ~s(msgstr "hej")
    end

    test "searches with regex flag" do
      output =
        capture_io(fn ->
          SearchValue.run(["^hej", "--locale", "sv", "--regex"])
        end)

      assert output =~ ~s(msgstr "hej")
    end

    test "searches with JSON output" do
      output =
        capture_io(fn ->
          SearchValue.run(["hej", "--locale", "sv", "--json"])
        end)

      # Should be valid JSON
      assert output =~ ~s("msgid":"hello")
      assert output =~ ~s("msgstr":"hej")
    end

    test "searches with limit option" do
      output =
        capture_io(fn ->
          SearchValue.run(["e", "--locale", "sv", "--limit", "1"])
        end)

      # Should only show one result
      lines = String.split(output, "\n", trim: true)
      # Count msgid entries (not blank lines)
      msgid_count = Enum.count(lines, &String.contains?(&1, "msgid"))
      assert msgid_count == 1
    end

    test "searches with short option aliases" do
      output =
        capture_io(fn ->
          SearchValue.run(["hej", "-l", "sv", "-j"])
        end)

      # Should work with short aliases
      assert output =~ ~s("msgstr":"hej")
    end

    test "returns empty output for no matches" do
      output =
        capture_io(fn ->
          SearchValue.run(["nonexistent", "--locale", "sv"])
        end)

      # Should be empty or just whitespace
      assert String.trim(output) == ""
    end
  end

  describe "run/1 error handling" do
    test "shows error for missing pattern argument" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(SearchValue.run(["--locale", "sv"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for missing locale option" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(SearchValue.run(["hej"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for non-existent locale" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(SearchValue.run(["hej", "--locale", "nonexistent"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for invalid options" do
      # Capture all output (stdout and stderr) to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(SearchValue.run(["hej", "--invalid-option", "value"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end
  end

  describe "run/1 with domain option" do
    test "can specify domain" do
      output =
        capture_io(fn ->
          SearchValue.run(["hej", "--locale", "sv", "--domain", "default"])
        end)

      assert output =~ ~s(msgstr "hej")
    end
  end
end
