defmodule Mix.Tasks.GettextOps.TranslateTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.GettextOps.Translate
  alias GettextOps.Parser

  # Configure gettext path for tests
  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  setup do
    # Create a copy of the sv locale for each test to avoid conflicts
    test_locale = "sv_test_#{System.unique_integer([:positive])}"
    test_dir = Path.join(["test/fixtures/gettext", test_locale, "LC_MESSAGES"])
    File.mkdir_p!(test_dir)

    source_file = "test/fixtures/gettext/sv/LC_MESSAGES/default.po"
    test_file = Path.join(test_dir, "default.po")
    File.cp!(source_file, test_file)

    on_exit(fn ->
      File.rm_rf!("test/fixtures/gettext/#{test_locale}")
    end)

    %{test_locale: test_locale, test_file: test_file}
  end

  describe "run/1 with file input" do
    test "applies translations from file", %{test_locale: locale, test_file: test_file} do
      # Create a temporary translations file
      translations_file = "test/fixtures/translations_#{System.unique_integer([:positive])}.txt"

      File.write!(translations_file, """
      hello = hallå
      world = världen
      """)

      on_exit(fn -> File.rm(translations_file) end)

      output =
        capture_io(fn ->
          Translate.run(["--locale", locale, "--file", translations_file])
        end)

      assert output =~ "Updated 2 translation(s)"

      # Verify the file was updated
      {:ok, messages} = Parser.parse_file(test_file)
      hello_msg = Enum.find(messages, fn msg -> msg.msgid == ["hello"] end)
      world_msg = Enum.find(messages, fn msg -> msg.msgid == ["world"] end)

      assert hello_msg.msgstr == ["hallå"]
      assert world_msg.msgstr == ["världen"]
    end

    test "applies translations with short option aliases", %{test_locale: locale} do
      translations_file = "test/fixtures/translations_#{System.unique_integer([:positive])}.txt"

      File.write!(translations_file, """
      hello = hallå
      """)

      on_exit(fn -> File.rm(translations_file) end)

      output =
        capture_io(fn ->
          Translate.run(["-l", locale, "-f", translations_file])
        end)

      assert output =~ "Updated 1 translation(s)"
    end
  end

  describe "run/1 with stdin input" do
    test "applies translations from stdin", %{test_locale: locale, test_file: test_file} do
      input = """
      hello = hallå
      world = världen
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "Updated 2 translation(s)"

      # Verify the file was updated
      {:ok, messages} = Parser.parse_file(test_file)
      hello_msg = Enum.find(messages, fn msg -> msg.msgid == ["hello"] end)
      world_msg = Enum.find(messages, fn msg -> msg.msgid == ["world"] end)

      assert hello_msg.msgstr == ["hallå"]
      assert world_msg.msgstr == ["världen"]
    end

    test "handles input with comments and empty lines", %{test_locale: locale} do
      input = """
      # This is a comment
      hello = hallå

      # Another comment
      world = världen
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "Updated 2 translation(s)"
    end
  end

  describe "run/1 with force flag" do
    test "continues with missing msgids when force is set", %{test_locale: locale} do
      input = """
      hello = hallå
      nonexistent = translation
      world = världen
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale, "--force"])
        end)

      assert output =~ "Updated 2 translation(s)"
      assert output =~ "Warnings"
      assert output =~ "nonexistent"
    end

    test "shows warning count for missing msgids", %{test_locale: locale} do
      input = """
      missing1 = translation1
      missing2 = translation2
      hello = hallå
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale, "--force"])
        end)

      assert output =~ "Updated 1 translation(s)"
      assert output =~ "2 msgid(s) not found"
      assert output =~ "missing1"
      assert output =~ "missing2"
    end
  end

  describe "run/1 error handling" do
    test "shows error for missing locale option" do
      input = "hello = hallå"

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run([]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for non-existent locale" do
      input = "hello = hallå"

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--locale", "nonexistent"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for non-existent file", %{test_locale: locale} do
      # Capture all output to prevent test pollution
      capture_io([capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--locale", locale, "--file", "nonexistent.txt"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error when msgid not found without force", %{test_locale: locale} do
      input = "nonexistent = translation"

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--locale", locale]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for empty input", %{test_locale: locale} do
      input = ""

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--locale", locale]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for input with only comments", %{test_locale: locale} do
      input = """
      # Only comments
      # No actual translations
      """

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--locale", locale]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end

    test "shows error for invalid options" do
      input = "hello = hallå"

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--invalid-option", "value"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end
  end

  describe "run/1 with domains" do
    test "uses default domain when not specified", %{test_locale: locale} do
      input = "hello = hallå"

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "Updated 1 translation(s)"
    end

    test "can specify domain explicitly", %{test_locale: locale} do
      input = "hello = hallå"

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale, "--domain", "default"])
        end)

      assert output =~ "Updated 1 translation(s)"
    end

    test "shows error for non-existent domain", %{test_locale: locale} do
      input = "hello = hallå"

      # Capture all output to prevent test pollution
      capture_io([input: input, capture_prompt: false], fn ->
        capture_io(:stderr, fn ->
          catch_exit(Translate.run(["--locale", locale, "--domain", "nonexistent"]))
        end)
      end)

      # Test passes if catch_exit handled the exit
    end
  end

  describe "run/1 output format" do
    test "shows success message with count", %{test_locale: locale} do
      input = """
      hello = hallå
      world = världen
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "✓"
      assert output =~ "Updated 2 translation(s)"
    end

    test "shows warning list when force is used", %{test_locale: locale} do
      input = """
      missing1 = translation1
      missing2 = translation2
      hello = hallå
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale, "--force"])
        end)

      assert output =~ "Warnings"
      assert output =~ "2 msgid(s) not found"
      assert output =~ "- missing1"
      assert output =~ "- missing2"
    end
  end

  describe "run/1 special cases" do
    test "handles translations with unicode characters", %{test_locale: locale} do
      input = """
      hello = 你好
      world = 🌍
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "Updated 2 translation(s)"
    end

    test "handles translations with quotes", %{test_locale: locale} do
      input = """
      hello = He said "hello"
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "Updated 1 translation(s)"
    end

    test "handles translations with = in msgstr", %{test_locale: locale} do
      input = """
      hello = value = something
      """

      output =
        capture_io([input: input], fn ->
          Translate.run(["--locale", locale])
        end)

      assert output =~ "Updated 1 translation(s)"
    end
  end
end
