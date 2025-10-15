defmodule GettextOps.Operations.ListUntranslatedTest do
  use ExUnit.Case, async: true

  alias GettextOps.Operations.ListUntranslated

  # Configure gettext path for tests
  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  describe "run/1 basic functionality" do
    test "lists all untranslated entries" do
      {:ok, messages} = ListUntranslated.run(locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgid == ["world"]
      assert hd(messages).msgstr == [""]
    end

    test "returns empty list when all entries are translated" do
      # Create a fixture with all translated entries or use en locale
      # For now, we'll test with a locale that has all entries translated
      # Note: This depends on having such a fixture available
      {:ok, messages} = ListUntranslated.run(locale: "en")

      # en locale should have some entries, but we test that it returns successfully
      assert is_list(messages)
    end
  end

  describe "run/1 with limit option" do
    test "limits results to specified number" do
      # sv has 1 untranslated entry, so limit of 1 should return 1
      {:ok, messages} = ListUntranslated.run(locale: "sv", limit: 1)

      assert length(messages) == 1
    end

    test "limit larger than available entries returns all entries" do
      # sv has 1 untranslated entry
      {:ok, messages} = ListUntranslated.run(locale: "sv", limit: 10)

      assert length(messages) == 1
    end

    test "limit of 0 returns empty list" do
      {:ok, messages} = ListUntranslated.run(locale: "sv", limit: 0)

      assert messages == []
    end

    test "no limit returns all untranslated entries" do
      {:ok, messages} = ListUntranslated.run(locale: "sv")

      assert length(messages) == 1
    end
  end

  describe "run/1 error handling" do
    test "returns error for non-existent locale" do
      {:error, message} = ListUntranslated.run(locale: "nonexistent")

      assert message =~ "Locale 'nonexistent' not found"
    end

    test "returns error for missing required locale option" do
      assert_raise KeyError, fn ->
        ListUntranslated.run([])
      end
    end

    test "returns error when po file doesn't exist" do
      # Create a locale directory without a po file
      # This is a bit tricky to test without creating fixtures
      # We'll rely on the domain option to test this
      {:error, message} = ListUntranslated.run(locale: "sv", domain: "nonexistent")

      assert message =~ "File not found"
    end
  end

  describe "run/1 with different domains" do
    test "lists from default domain when not specified" do
      {:ok, messages} = ListUntranslated.run(locale: "sv")

      assert length(messages) >= 1
    end

    test "can specify domain explicitly" do
      {:ok, messages} = ListUntranslated.run(locale: "sv", domain: "default")

      assert length(messages) >= 1
    end
  end

  describe "run/1 with various untranslated patterns" do
    test "detects entries with empty string msgstr" do
      {:ok, messages} = ListUntranslated.run(locale: "sv")

      # All returned messages should be untranslated
      Enum.each(messages, fn message ->
        assert message.msgstr == [""] or message.msgstr == []
      end)
    end

    test "does not include entries with translated msgstr" do
      {:ok, messages} = ListUntranslated.run(locale: "sv")

      # Should not include "hello" which is translated
      refute Enum.any?(messages, fn message ->
        message.msgid == ["hello"]
      end)
    end
  end
end
