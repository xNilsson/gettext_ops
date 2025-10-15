defmodule GettextOps.WriterTest do
  use ExUnit.Case, async: true
  doctest GettextOps.Writer

  alias GettextOps.{Writer, Parser, Entry}

  @fixtures_dir "test/fixtures"
  @test_po Path.join(@fixtures_dir, "test.po")
  @empty_po Path.join(@fixtures_dir, "empty.po")

  setup do
    # Create a temporary directory for test files
    tmp_dir = System.tmp_dir!()
    test_file = Path.join(tmp_dir, "test_writer_#{:erlang.unique_integer([:positive])}.po")

    on_exit(fn ->
      if File.exists?(test_file), do: File.rm!(test_file)
    end)

    {:ok, test_file: test_file}
  end

  describe "update_file/2" do
    test "updates messages using transformation function", %{test_file: test_file} do
      # Copy test file to temp location
      File.cp!(@test_po, test_file)

      # Update all messages to have a prefix
      update_fn = fn msg ->
        current_msgstr = Entry.get_msgstr(msg)
        Entry.update_msgstr(msg, "PREFIX: #{current_msgstr}")
      end

      assert :ok = Writer.update_file(test_file, update_fn)

      # Verify updates
      assert {:ok, messages} = Parser.parse_file(test_file)

      Enum.each(messages, fn msg ->
        msgstr = Entry.get_msgstr(msg)

        if msgstr != "" do
          assert String.starts_with?(msgstr, "PREFIX: ")
        end
      end)
    end

    test "preserves message structure and references", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      # Get original messages
      assert {:ok, original_messages} = Parser.parse_file(test_file)
      original_count = length(original_messages)

      # Update with identity function (no changes)
      update_fn = fn msg -> msg end
      assert :ok = Writer.update_file(test_file, update_fn)

      # Verify structure is preserved
      assert {:ok, updated_messages} = Parser.parse_file(test_file)
      assert length(updated_messages) == original_count
    end

    test "returns error for non-existent file", %{test_file: test_file} do
      update_fn = fn msg -> msg end
      assert {:error, :enoent} = Writer.update_file(test_file, update_fn)
    end

    test "preserves headers and comments", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      # Get original full structure
      assert {:ok, original_po} = Parser.parse_file_full(test_file)
      original_headers = original_po.headers

      # Update messages
      update_fn = fn msg -> Entry.update_msgstr(msg, "Updated") end
      assert :ok = Writer.update_file(test_file, update_fn)

      # Verify headers are preserved
      assert {:ok, updated_po} = Parser.parse_file_full(test_file)
      assert updated_po.headers == original_headers
    end
  end

  describe "update_translations/2" do
    test "updates specific translations by msgid", %{test_file: test_file} do
      File.cp!(@empty_po, test_file)

      translations = %{
        "Profile settings" => "Profilinställningar",
        "Invalid credentials" => "Ogiltiga uppgifter"
      }

      assert {:ok, %{updated: count}} = Writer.update_translations(test_file, translations)
      assert count == 2

      # Verify translations were updated
      assert {:ok, messages} = Parser.parse_file(test_file)

      profile_msg =
        Enum.find(messages, fn msg ->
          Entry.get_msgid(msg) == "Profile settings"
        end)

      assert Entry.get_msgstr(profile_msg) == "Profilinställningar"

      creds_msg =
        Enum.find(messages, fn msg ->
          Entry.get_msgid(msg) == "Invalid credentials"
        end)

      assert Entry.get_msgstr(creds_msg) == "Ogiltiga uppgifter"
    end

    test "does not update messages not in translation map", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      # Get original message
      assert {:ok, original_messages} = Parser.parse_file(test_file)

      original_msg =
        Enum.find(original_messages, fn msg ->
          Entry.get_msgid(msg) == "User created successfully"
        end)

      original_msgstr = Entry.get_msgstr(original_msg)

      # Update only one message
      translations = %{"Welcome to Phoenix!" => "NEW TRANSLATION"}
      assert {:ok, %{updated: 1}} = Writer.update_translations(test_file, translations)

      # Verify other messages unchanged
      assert {:ok, updated_messages} = Parser.parse_file(test_file)

      unchanged_msg =
        Enum.find(updated_messages, fn msg ->
          Entry.get_msgid(msg) == "User created successfully"
        end)

      assert Entry.get_msgstr(unchanged_msg) == original_msgstr
    end

    test "returns count of 0 when no messages match", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      translations = %{"NONEXISTENT" => "Translation"}
      assert {:ok, %{updated: 0}} = Writer.update_translations(test_file, translations)
    end

    test "handles empty translation map", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      translations = %{}
      assert {:ok, %{updated: 0}} = Writer.update_translations(test_file, translations)
    end
  end

  describe "change_msgid/3" do
    test "changes msgid for matching messages", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      old_msgid = "Welcome to Phoenix!"
      new_msgid = "Welcome to our app!"

      assert {:ok, %{updated: count}} = Writer.change_msgid(test_file, old_msgid, new_msgid)
      assert count == 1

      # Verify msgid was changed
      assert {:ok, messages} = Parser.parse_file(test_file)

      # Old msgid should not exist
      old_msg = Enum.find(messages, fn msg -> Entry.get_msgid(msg) == old_msgid end)
      assert old_msg == nil

      # New msgid should exist
      new_msg = Enum.find(messages, fn msg -> Entry.get_msgid(msg) == new_msgid end)
      assert new_msg != nil
    end

    test "preserves msgstr when changing msgid", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      # Get original msgstr
      assert {:ok, original_messages} = Parser.parse_file(test_file)

      original_msg =
        Enum.find(original_messages, fn msg ->
          Entry.get_msgid(msg) == "Welcome to Phoenix!"
        end)

      original_msgstr = Entry.get_msgstr(original_msg)

      # Change msgid
      assert {:ok, %{updated: 1}} =
               Writer.change_msgid(test_file, "Welcome to Phoenix!", "New msgid")

      # Verify msgstr is preserved
      assert {:ok, updated_messages} = Parser.parse_file(test_file)

      updated_msg =
        Enum.find(updated_messages, fn msg ->
          Entry.get_msgid(msg) == "New msgid"
        end)

      assert Entry.get_msgstr(updated_msg) == original_msgstr
    end

    test "returns count of 0 when msgid not found", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      assert {:ok, %{updated: 0}} =
               Writer.change_msgid(test_file, "NONEXISTENT", "New")
    end

    test "does not change other messages", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      assert {:ok, original_messages} = Parser.parse_file(test_file)
      original_count = length(original_messages)

      assert {:ok, %{updated: 1}} =
               Writer.change_msgid(test_file, "Welcome to Phoenix!", "New msgid")

      assert {:ok, updated_messages} = Parser.parse_file(test_file)
      assert length(updated_messages) == original_count
    end
  end

  describe "write_file/3" do
    test "creates a new .po file with messages", %{test_file: test_file} do
      messages = [
        %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]},
        %Expo.Message.Singular{msgid: ["Goodbye"], msgstr: ["Hejdå"]}
      ]

      assert :ok = Writer.write_file(test_file, messages)
      assert File.exists?(test_file)

      # Verify messages can be read back
      assert {:ok, read_messages} = Parser.parse_file(test_file)
      assert length(read_messages) == 2

      hello_msg = Enum.find(read_messages, fn msg -> Entry.get_msgid(msg) == "Hello" end)
      assert Entry.get_msgstr(hello_msg) == "Hej"
    end

    test "creates file with custom headers", %{test_file: test_file} do
      messages = [%Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}]
      headers = ["## Custom header", "## Another header"]

      assert :ok = Writer.write_file(test_file, messages, headers)

      assert {:ok, po_messages} = Parser.parse_file_full(test_file)
      assert po_messages.headers == headers
    end

    test "creates file with default headers when not specified", %{test_file: test_file} do
      messages = [%Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}]

      assert :ok = Writer.write_file(test_file, messages)

      assert {:ok, po_messages} = Parser.parse_file_full(test_file)
      assert is_list(po_messages.headers)
      assert length(po_messages.headers) > 0
    end

    test "overwrites existing file", %{test_file: test_file} do
      # Create initial file
      messages1 = [%Expo.Message.Singular{msgid: ["First"], msgstr: ["Första"]}]
      assert :ok = Writer.write_file(test_file, messages1)

      # Overwrite with new messages
      messages2 = [%Expo.Message.Singular{msgid: ["Second"], msgstr: ["Andra"]}]
      assert :ok = Writer.write_file(test_file, messages2)

      # Verify only new messages exist
      assert {:ok, read_messages} = Parser.parse_file(test_file)
      assert length(read_messages) == 1

      msg = List.first(read_messages)
      assert Entry.get_msgid(msg) == "Second"
    end
  end

  describe "round-trip tests" do
    test "parse → update → parse preserves file integrity", %{test_file: test_file} do
      File.cp!(@test_po, test_file)

      # Parse original
      assert {:ok, original_messages} = Parser.parse_file(test_file)

      # Update with identity function
      update_fn = fn msg -> msg end
      assert :ok = Writer.update_file(test_file, update_fn)

      # Parse again
      assert {:ok, final_messages} = Parser.parse_file(test_file)

      # Compare message count and content
      assert length(final_messages) == length(original_messages)

      Enum.zip(original_messages, final_messages)
      |> Enum.each(fn {orig, final} ->
        assert Entry.get_msgid(orig) == Entry.get_msgid(final)
        assert Entry.get_msgstr(orig) == Entry.get_msgstr(final)
      end)
    end

    test "handles multi-line messages correctly", %{test_file: test_file} do
      messages = [
        %Expo.Message.Singular{
          msgid: ["Line 1\n", "Line 2"],
          msgstr: ["Rad 1\n", "Rad 2"]
        }
      ]

      assert :ok = Writer.write_file(test_file, messages)
      assert {:ok, read_messages} = Parser.parse_file(test_file)

      assert length(read_messages) == 1
    end
  end
end
