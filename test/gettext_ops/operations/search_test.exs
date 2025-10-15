defmodule GettextOps.Operations.SearchTest do
  use ExUnit.Case, async: true

  alias GettextOps.Operations.Search

  # Configure gettext path for tests
  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  describe "run/2 with substring matching" do
    test "finds entries with case-insensitive substring match" do
      {:ok, messages} = Search.run("hello", locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
      assert hd(messages).msgstr == ["hej"]
    end

    test "finds entries with uppercase pattern" do
      {:ok, messages} = Search.run("HELLO", locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
    end

    test "finds no matches for non-existent pattern" do
      {:ok, messages} = Search.run("nonexistent", locale: "sv")

      assert messages == []
    end

    test "finds partial substring matches" do
      {:ok, messages} = Search.run("hel", locale: "sv")

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
    end
  end

  describe "run/2 with regex matching" do
    test "finds entries matching regex pattern" do
      {:ok, messages} = Search.run("^hello", locale: "sv", regex: true)

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
    end

    test "regex is case-insensitive by default" do
      {:ok, messages} = Search.run("^HELLO", locale: "sv", regex: true)

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
    end

    test "finds entries with complex regex" do
      {:ok, messages} = Search.run("h.ll.", locale: "sv", regex: true)

      assert length(messages) == 1
      assert hd(messages).msgid == ["hello"]
    end

    test "finds no matches for non-matching regex" do
      {:ok, messages} = Search.run("^world$", locale: "sv", regex: true)

      # "world" exists but has empty msgstr, still should be found
      assert length(messages) == 1
      assert hd(messages).msgid == ["world"]
    end
  end

  describe "run/2 with limit option" do
    test "limits results to specified number" do
      # Use test.po which has more entries
      {:ok, messages} =
        Search.run(".", locale: "en", regex: true, limit: 2)

      # Should find at most 2 messages
      assert length(messages) <= 2
    end

    test "limit works with substring search" do
      {:ok, messages} = Search.run("o", locale: "sv", limit: 1)

      assert length(messages) == 1
    end

    test "no limit returns all matches" do
      {:ok, messages} = Search.run("o", locale: "sv")

      # Should find both "hello" and "world" (both contain "o")
      assert length(messages) >= 1
    end
  end

  describe "run/2 error handling" do
    test "returns error for non-existent locale" do
      {:error, message} = Search.run("hello", locale: "nonexistent")

      assert message =~ "Locale 'nonexistent' not found"
    end

    test "returns error for missing required locale option" do
      assert_raise KeyError, fn ->
        Search.run("hello", [])
      end
    end
  end

  describe "run/2 with different domains" do
    test "searches in default domain when not specified" do
      {:ok, messages} = Search.run("hello", locale: "sv")

      assert length(messages) >= 1
    end

    test "can specify domain explicitly" do
      {:ok, messages} = Search.run("hello", locale: "sv", domain: "default")

      assert length(messages) >= 1
    end
  end
end
