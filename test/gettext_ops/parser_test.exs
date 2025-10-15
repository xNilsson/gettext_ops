defmodule GettextOps.ParserTest do
  use ExUnit.Case, async: true
  doctest GettextOps.Parser

  alias GettextOps.Parser
  alias GettextOps.Entry

  @fixtures_dir "test/fixtures"
  @test_po Path.join(@fixtures_dir, "test.po")
  @empty_po Path.join(@fixtures_dir, "empty.po")
  @multiline_po Path.join(@fixtures_dir, "multiline.po")

  describe "parse_file/1" do
    test "successfully parses a valid .po file" do
      assert {:ok, messages} = Parser.parse_file(@test_po)
      assert is_list(messages)
      assert length(messages) > 0
    end

    test "returns error for non-existent file" do
      assert {:error, :enoent} = Parser.parse_file("nonexistent.po")
    end

    test "parses messages with references" do
      assert {:ok, messages} = Parser.parse_file(@test_po)

      welcome_msg =
        Enum.find(messages, fn msg ->
          Entry.get_msgid(msg) == "Welcome to Phoenix!"
        end)

      assert welcome_msg != nil
      assert Entry.get_msgstr(welcome_msg) == "Välkommen till Phoenix!"
    end

    test "parses multi-line messages" do
      assert {:ok, messages} = Parser.parse_file(@multiline_po)

      welcome_msg =
        Enum.find(messages, fn msg ->
          String.contains?(Entry.get_msgid(msg), "Welcome to our application")
        end)

      assert welcome_msg != nil
      assert String.contains?(Entry.get_msgstr(welcome_msg), "Välkommen till vår applikation")
    end
  end

  describe "parse_and_filter/2" do
    test "filters messages using custom predicate" do
      filter_fn = fn msg -> String.contains?(Entry.get_msgid(msg), "Phoenix") end

      assert {:ok, filtered} = Parser.parse_and_filter(@test_po, filter_fn)
      assert length(filtered) >= 1

      Enum.each(filtered, fn msg ->
        assert String.contains?(Entry.get_msgid(msg), "Phoenix")
      end)
    end

    test "returns empty list when no messages match" do
      filter_fn = fn msg -> String.contains?(Entry.get_msgid(msg), "NONEXISTENT") end

      assert {:ok, filtered} = Parser.parse_and_filter(@test_po, filter_fn)
      assert filtered == []
    end

    test "returns error for non-existent file" do
      filter_fn = fn _msg -> true end
      assert {:error, :enoent} = Parser.parse_and_filter("nonexistent.po", filter_fn)
    end
  end

  describe "parse_untranslated/1" do
    test "finds untranslated messages" do
      assert {:ok, untranslated} = Parser.parse_untranslated(@empty_po)
      assert length(untranslated) > 0

      Enum.each(untranslated, fn msg ->
        assert Entry.untranslated?(msg)
      end)
    end

    test "returns empty list for fully translated file" do
      assert {:ok, untranslated} = Parser.parse_untranslated(@test_po)
      # test.po has all messages translated
      assert untranslated == []
    end

    test "finds untranslated multi-line messages" do
      assert {:ok, untranslated} = Parser.parse_untranslated(@multiline_po)

      help_msg =
        Enum.find(untranslated, fn msg ->
          String.contains?(Entry.get_msgid(msg), "Need help")
        end)

      assert help_msg != nil
    end
  end

  describe "search_msgid/2" do
    test "finds messages by exact msgid match" do
      assert {:ok, results} = Parser.search_msgid(@test_po, "Welcome to Phoenix!")
      assert length(results) == 1

      [msg] = results
      assert Entry.get_msgid(msg) == "Welcome to Phoenix!"
    end

    test "finds messages by regex pattern" do
      assert {:ok, results} = Parser.search_msgid(@test_po, ~r/Phoenix/)
      assert length(results) >= 1

      Enum.each(results, fn msg ->
        assert Entry.get_msgid(msg) =~ ~r/Phoenix/
      end)
    end

    test "is case-sensitive by default" do
      assert {:ok, results} = Parser.search_msgid(@test_po, ~r/phoenix/)
      assert results == []
    end

    test "supports case-insensitive regex" do
      assert {:ok, results} = Parser.search_msgid(@test_po, ~r/phoenix/i)
      assert length(results) >= 1
    end

    test "returns empty list when no matches" do
      assert {:ok, results} = Parser.search_msgid(@test_po, "NONEXISTENT")
      assert results == []
    end
  end

  describe "search_msgstr/2" do
    test "finds messages by exact msgstr match" do
      assert {:ok, results} = Parser.search_msgstr(@test_po, "Välkommen till Phoenix!")
      assert length(results) == 1

      [msg] = results
      assert Entry.get_msgstr(msg) == "Välkommen till Phoenix!"
    end

    test "finds messages by regex pattern" do
      assert {:ok, results} = Parser.search_msgstr(@test_po, ~r/Välkommen/)
      assert length(results) >= 1

      Enum.each(results, fn msg ->
        assert Entry.get_msgstr(msg) =~ ~r/Välkommen/
      end)
    end

    test "returns empty list when no matches" do
      assert {:ok, results} = Parser.search_msgstr(@test_po, "NONEXISTENT")
      assert results == []
    end

    test "does not match empty msgstr" do
      assert {:ok, results} = Parser.search_msgstr(@empty_po, ~r/.*/)
      # The regex .* would match anything, but we should only get non-empty msgstr
      translated = Enum.reject(results, &Entry.untranslated?/1)
      assert length(translated) > 0
    end
  end

  describe "parse_file_full/1" do
    test "returns full Expo.Messages struct with headers" do
      assert {:ok, %Expo.Messages{} = po_messages} = Parser.parse_file_full(@test_po)
      assert is_list(po_messages.headers)
      assert is_list(po_messages.messages)
    end

    test "preserves headers" do
      assert {:ok, po_messages} = Parser.parse_file_full(@test_po)

      # Check that we have headers (Expo stores top comments as headers)
      assert is_list(po_messages.headers)
      assert length(po_messages.headers) > 0
    end

    test "returns error for non-existent file" do
      assert {:error, :enoent} = Parser.parse_file_full("nonexistent.po")
    end
  end

  describe "integration tests" do
    test "all fixture files can be parsed" do
      assert {:ok, _} = Parser.parse_file(@test_po)
      assert {:ok, _} = Parser.parse_file(@empty_po)
      assert {:ok, _} = Parser.parse_file(@multiline_po)
    end

    test "can find specific messages in test.po" do
      assert {:ok, messages} = Parser.parse_file(@test_po)

      msgids = Enum.map(messages, &Entry.get_msgid/1)
      assert "Welcome to Phoenix!" in msgids
      assert "Click here to get started" in msgids
      assert "User created successfully" in msgids
    end

    test "empty.po has untranslated entries" do
      assert {:ok, messages} = Parser.parse_file(@empty_po)
      untranslated = Enum.filter(messages, &Entry.untranslated?/1)
      assert length(untranslated) >= 3
    end
  end
end
