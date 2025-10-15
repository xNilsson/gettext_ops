defmodule GettextOps.Operations.TranslateTest do
  use ExUnit.Case, async: false

  alias GettextOps.Operations.Translate
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

  describe "parse_translations/1" do
    test "parses valid translation input" do
      input = """
      Sign In = Logga in
      Sign Out = Logga ut
      """

      {:ok, translations} = Translate.parse_translations(input)

      assert translations == %{
               "Sign In" => "Logga in",
               "Sign Out" => "Logga ut"
             }
    end

    test "handles empty lines" do
      input = """
      Sign In = Logga in

      Sign Out = Logga ut
      """

      {:ok, translations} = Translate.parse_translations(input)

      assert map_size(translations) == 2
    end

    test "ignores comment lines starting with #" do
      input = """
      # This is a comment
      Sign In = Logga in
      # Another comment
      Sign Out = Logga ut
      """

      {:ok, translations} = Translate.parse_translations(input)

      assert map_size(translations) == 2
    end

    test "ignores lines without = separator" do
      input = """
      Sign In = Logga in
      This line has no separator
      Sign Out = Logga ut
      """

      {:ok, translations} = Translate.parse_translations(input)

      assert map_size(translations) == 2
    end

    test "handles lines with multiple = signs" do
      input = """
      Error: Invalid = Fel: Ogiltig = värde
      """

      {:ok, translations} = Translate.parse_translations(input)

      # Should split on first = only
      assert translations["Error: Invalid"] == "Fel: Ogiltig = värde"
    end

    test "trims whitespace around msgid and msgstr" do
      input = """
        Sign In   =   Logga in
      """

      {:ok, translations} = Translate.parse_translations(input)

      assert translations["Sign In"] == "Logga in"
    end

    test "handles empty input" do
      {:ok, translations} = Translate.parse_translations("")

      assert translations == %{}
    end

    test "returns empty map for input with only comments" do
      input = """
      # Comment 1
      # Comment 2
      """

      {:ok, translations} = Translate.parse_translations(input)

      assert translations == %{}
    end
  end

  describe "run/2 basic functionality" do
    test "updates existing translation", %{test_locale: locale, test_file: test_file} do
      translations = %{"world" => "världen"}

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 1
      assert result.not_found == []

      # Verify the file was updated
      {:ok, messages} = Parser.parse_file(test_file)
      world_msg = Enum.find(messages, fn msg -> msg.msgid == ["world"] end)
      assert world_msg.msgstr == ["världen"]
    end

    test "updates multiple translations", %{test_locale: locale, test_file: test_file} do
      translations = %{
        "hello" => "hallå",
        "world" => "världen"
      }

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 2
      assert result.not_found == []

      # Verify both were updated
      {:ok, messages} = Parser.parse_file(test_file)
      hello_msg = Enum.find(messages, fn msg -> msg.msgid == ["hello"] end)
      world_msg = Enum.find(messages, fn msg -> msg.msgid == ["world"] end)

      assert hello_msg.msgstr == ["hallå"]
      assert world_msg.msgstr == ["världen"]
    end

    test "preserves other message fields", %{test_locale: locale, test_file: test_file} do
      # Read original file to get a message's metadata
      {:ok, original_messages} = Parser.parse_file(test_file)
      original_hello = Enum.find(original_messages, fn msg -> msg.msgid == ["hello"] end)

      translations = %{"hello" => "hallå"}
      {:ok, _result} = Translate.run(translations, locale: locale)

      # Read updated file
      {:ok, updated_messages} = Parser.parse_file(test_file)
      updated_hello = Enum.find(updated_messages, fn msg -> msg.msgid == ["hello"] end)

      # Check that msgstr changed but msgid and other fields preserved
      assert updated_hello.msgstr == ["hallå"]
      assert updated_hello.msgid == original_hello.msgid
      assert updated_hello.comments == original_hello.comments
      assert updated_hello.references == original_hello.references
    end
  end

  describe "run/2 with missing msgids" do
    test "returns error when msgid not found without force", %{test_locale: locale} do
      translations = %{"nonexistent" => "translation"}

      {:error, message} = Translate.run(translations, locale: locale)

      assert message =~ "msgid not found"
      assert message =~ "nonexistent"
    end

    test "returns error with all missing msgids", %{test_locale: locale} do
      translations = %{
        "missing1" => "translation1",
        "missing2" => "translation2"
      }

      {:error, message} = Translate.run(translations, locale: locale)

      assert message =~ "msgid not found"
      assert message =~ "missing1"
      assert message =~ "missing2"
    end

    test "returns error even if some msgids exist", %{test_locale: locale} do
      translations = %{
        "hello" => "hallå",
        "nonexistent" => "translation"
      }

      {:error, message} = Translate.run(translations, locale: locale)

      assert message =~ "msgid not found"
      assert message =~ "nonexistent"
    end
  end

  describe "run/2 with force option" do
    test "succeeds with force when msgid not found", %{test_locale: locale} do
      translations = %{"nonexistent" => "translation"}

      {:ok, result} = Translate.run(translations, locale: locale, force: true)

      assert result.updated == 0
      assert result.not_found == ["nonexistent"]
    end

    test "updates existing and reports missing with force", %{test_locale: locale} do
      translations = %{
        "hello" => "hallå",
        "nonexistent" => "translation"
      }

      {:ok, result} = Translate.run(translations, locale: locale, force: true)

      assert result.updated == 1
      assert result.not_found == ["nonexistent"]
    end

    test "preserves order of not_found msgids", %{test_locale: locale} do
      translations = %{
        "missing1" => "translation1",
        "hello" => "hallå",
        "missing2" => "translation2",
        "missing3" => "translation3"
      }

      {:ok, result} = Translate.run(translations, locale: locale, force: true)

      assert result.updated == 1
      # Order should be preserved as they appear in input
      assert result.not_found == ["missing1", "missing2", "missing3"]
    end
  end

  describe "run/2 error handling" do
    test "returns error for non-existent locale" do
      translations = %{"hello" => "translation"}

      {:error, message} = Translate.run(translations, locale: "nonexistent")

      assert message =~ "Locale 'nonexistent' not found"
    end

    test "returns error when domain file doesn't exist", %{test_locale: locale} do
      translations = %{"hello" => "translation"}

      {:error, message} = Translate.run(translations, locale: locale, domain: "nonexistent")

      assert message =~ "File not found"
    end

    test "returns error for missing required locale option" do
      translations = %{"hello" => "translation"}

      assert_raise KeyError, fn ->
        Translate.run(translations, [])
      end
    end
  end

  describe "run/2 with domains" do
    test "uses default domain when not specified", %{test_locale: locale} do
      translations = %{"hello" => "hallå"}

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 1
    end

    test "can specify domain explicitly", %{test_locale: locale} do
      translations = %{"hello" => "hallå"}

      {:ok, result} = Translate.run(translations, locale: locale, domain: "default")

      assert result.updated == 1
    end
  end

  describe "run/2 atomic updates" do
    test "creates temporary file during update", %{test_locale: locale, test_file: test_file} do
      # This is hard to test directly, but we can verify the file is valid after update
      translations = %{"hello" => "hallå"}

      {:ok, _result} = Translate.run(translations, locale: locale)

      # File should be valid and parseable
      assert {:ok, _messages} = Parser.parse_file(test_file)

      # Temp file should not exist
      refute File.exists?(test_file <> ".tmp")
    end

    test "file remains valid even with unicode characters", %{test_locale: locale} do
      translations = %{
        "hello" => "你好",
        "world" => "🌍"
      }

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 2
    end
  end

  describe "run/2 with special cases" do
    test "handles empty translation string", %{test_locale: locale} do
      translations = %{"hello" => ""}

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 1
    end

    test "handles translations with newlines", %{test_locale: locale} do
      translations = %{"hello" => "multi\\nline"}

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 1
    end

    test "handles translations with quotes", %{test_locale: locale} do
      translations = %{"hello" => "He said \"hello\""}

      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 1
    end
  end

  describe "run/2 integration" do
    test "full workflow: parse and apply translations", %{test_locale: locale} do
      input = """
      hello = hallå
      world = världen
      """

      {:ok, translations} = Translate.parse_translations(input)
      {:ok, result} = Translate.run(translations, locale: locale)

      assert result.updated == 2
      assert result.not_found == []
    end

    test "workflow with force flag", %{test_locale: locale} do
      input = """
      hello = hallå
      nonexistent = translation
      world = världen
      """

      {:ok, translations} = Translate.parse_translations(input)
      {:ok, result} = Translate.run(translations, locale: locale, force: true)

      assert result.updated == 2
      assert result.not_found == ["nonexistent"]
    end
  end
end
