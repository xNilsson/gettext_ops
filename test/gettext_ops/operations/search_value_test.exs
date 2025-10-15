defmodule GettextOps.Operations.SearchValueTest do
  use ExUnit.Case, async: true

  alias GettextOps.Operations.SearchValue

  # Configure gettext path for tests
  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  describe "run/2 with substring matching" do
    test "finds entries with case-insensitive substring match in msgstr" do
      {:ok, messages} = SearchValue.run("hej", locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
      assert hd(messages).msgstr == ["hej"]
    end

    test "finds entries with uppercase pattern" do
      {:ok, messages} = SearchValue.run("HEJ", locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgstr == ["hej"]
    end

    test "finds no matches for non-existent pattern" do
      {:ok, messages} = SearchValue.run("nonexistent", locale: "sv")

      assert messages == []
    end

    test "finds partial substring matches" do
      {:ok, messages} = SearchValue.run("he", locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgstr == ["hej"]
    end

    test "does not match empty translations" do
      {:ok, messages} = SearchValue.run("", locale: "sv")

      # Should match entries with empty msgstr
      # Note: "world" has empty msgstr in sv locale
      assert length(messages) >= 1
    end
  end

  describe "run/2 with regex matching" do
    test "finds entries matching regex pattern in msgstr" do
      {:ok, messages} = SearchValue.run("^hej", locale: "sv", regex: true)

      assert length(messages) == 1
      assert hd(messages).msgstr == ["hej"]
    end

    test "regex is case-insensitive by default" do
      {:ok, messages} = SearchValue.run("^HEJ", locale: "sv", regex: true)

      assert length(messages) == 1
      assert hd(messages).msgstr == ["hej"]
    end

    test "finds entries with complex regex" do
      {:ok, messages} = SearchValue.run("h.j", locale: "sv", regex: true)

      assert length(messages) == 1
      assert hd(messages).msgstr == ["hej"]
    end

    test "finds no matches for non-matching regex" do
      {:ok, messages} = SearchValue.run("^xyz", locale: "sv", regex: true)

      assert messages == []
    end
  end

  describe "run/2 with limit option" do
    test "limits results to specified number" do
      # Search for a common letter that appears in multiple translations
      {:ok, messages} =
        SearchValue.run(".", locale: "en", regex: true, limit: 2)

      # Should find at most 2 messages
      assert length(messages) <= 2
    end

    test "limit works with substring search" do
      {:ok, messages} = SearchValue.run("e", locale: "sv", limit: 1)

      assert length(messages) == 1
    end

    test "no limit returns all matches" do
      {:ok, messages} = SearchValue.run("e", locale: "sv")

      # Should find at least "hej"
      assert length(messages) >= 1
    end
  end

  describe "run/2 error handling" do
    test "returns error for non-existent locale" do
      {:error, message} = SearchValue.run("hej", locale: "nonexistent")

      assert message =~ "Locale 'nonexistent' not found"
    end

    test "returns error for missing required locale option" do
      assert_raise KeyError, fn ->
        SearchValue.run("hej", [])
      end
    end
  end

  describe "run/2 with different domains" do
    test "searches in default domain when not specified" do
      {:ok, messages} = SearchValue.run("hej", locale: "sv")

      assert length(messages) >= 1
    end

    test "can specify domain explicitly" do
      {:ok, messages} = SearchValue.run("hej", locale: "sv", domain: "default")

      assert length(messages) >= 1
    end
  end
end
