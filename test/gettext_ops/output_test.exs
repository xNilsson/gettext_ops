defmodule GettextOps.OutputTest do
  use ExUnit.Case, async: true

  alias Expo.Message
  alias GettextOps.Output

  doctest GettextOps.Output

  describe "format_text/1" do
    test "formats simple singular message" do
      message = %Message.Singular{
        msgid: ["Sign In"],
        msgstr: [""]
      }

      expected = """
      msgid "Sign In"
      msgstr ""
      """

      assert Output.format_text(message) == expected
    end

    test "formats singular message with translation" do
      message = %Message.Singular{
        msgid: ["Welcome"],
        msgstr: ["Välkommen"]
      }

      expected = """
      msgid "Welcome"
      msgstr "Välkommen"
      """

      assert Output.format_text(message) == expected
    end

    test "formats multi-line msgid and msgstr" do
      message = %Message.Singular{
        msgid: ["This is a long ", "message that spans ", "multiple lines"],
        msgstr: ["Detta är ett långt ", "meddelande som sträcker sig ", "över flera rader"]
      }

      expected = """
      msgid "This is a long message that spans multiple lines"
      msgstr "Detta är ett långt meddelande som sträcker sig över flera rader"
      """

      assert Output.format_text(message) == expected
    end

    test "escapes special characters in text output" do
      message = %Message.Singular{
        msgid: ["Quote: \"Hello\""],
        msgstr: ["Citat: \"Hej\""]
      }

      expected = """
      msgid "Quote: \\"Hello\\""
      msgstr "Citat: \\"Hej\\""
      """

      assert Output.format_text(message) == expected
    end

    test "escapes newlines in text output" do
      message = %Message.Singular{
        msgid: ["Line 1\nLine 2"],
        msgstr: ["Rad 1\nRad 2"]
      }

      expected = """
      msgid "Line 1\\nLine 2"
      msgstr "Rad 1\\nRad 2"
      """

      assert Output.format_text(message) == expected
    end

    test "formats plural messages" do
      message = %Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgstr: %{
          0 => ["ett objekt"],
          1 => ["flera objekt"]
        }
      }

      result = Output.format_text(message)

      assert result =~ ~s(msgid "item")
      assert result =~ ~s(msgid_plural "items")
      assert result =~ ~s(msgstr[0] "ett objekt")
      assert result =~ ~s(msgstr[1] "flera objekt")
    end

    test "formats empty plural message" do
      message = %Message.Plural{
        msgid: ["file"],
        msgid_plural: ["files"],
        msgstr: %{
          0 => [""],
          1 => [""]
        }
      }

      result = Output.format_text(message)

      assert result =~ ~s(msgid "file")
      assert result =~ ~s(msgid_plural "files")
      assert result =~ ~s(msgstr[0] "")
      assert result =~ ~s(msgstr[1] "")
    end
  end

  describe "format_json/1" do
    test "formats simple singular message as JSON" do
      message = %Message.Singular{
        msgid: ["Sign In"],
        msgstr: [""]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["msgid"] == "Sign In"
      assert decoded["msgstr"] == ""
      refute Map.has_key?(decoded, "references")
    end

    test "formats singular message with translation" do
      message = %Message.Singular{
        msgid: ["Welcome"],
        msgstr: ["Välkommen"]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["msgid"] == "Welcome"
      assert decoded["msgstr"] == "Välkommen"
    end

    test "includes references in JSON output" do
      message = %Message.Singular{
        msgid: ["Welcome"],
        msgstr: ["Välkommen"],
        references: [[{"lib/home.ex", 5}]]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["msgid"] == "Welcome"
      assert decoded["msgstr"] == "Välkommen"
      assert decoded["references"] == ["lib/home.ex:5"]
    end

    test "includes multiple references" do
      message = %Message.Singular{
        msgid: ["Sign In"],
        msgstr: [""],
        references: [[{"lib/auth.ex", 12}, {"lib/session.ex", 42}]]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["references"] == ["lib/auth.ex:12", "lib/session.ex:42"]
    end

    test "includes comments in JSON output" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"],
        comments: ["# This is a comment", "# Another comment"]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["comments"] == ["# This is a comment", "# Another comment"]
    end

    test "includes flags in JSON output" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"],
        flags: [["fuzzy"]]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["flags"] == [["fuzzy"]]
    end

    test "handles multi-line strings in JSON" do
      message = %Message.Singular{
        msgid: ["Line 1\n", "Line 2\n", "Line 3"],
        msgstr: ["Rad 1\n", "Rad 2\n", "Rad 3"]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["msgid"] == "Line 1\nLine 2\nLine 3"
      assert decoded["msgstr"] == "Rad 1\nRad 2\nRad 3"
    end

    test "escapes special characters in JSON" do
      message = %Message.Singular{
        msgid: ["Quote: \"Hello\" and newline\n"],
        msgstr: ["Citat: \"Hej\" och nyrad\n"]
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["msgid"] == "Quote: \"Hello\" and newline\n"
      assert decoded["msgstr"] == "Citat: \"Hej\" och nyrad\n"
    end

    test "formats plural message as JSON (returns first form)" do
      message = %Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgstr: %{
          0 => ["ett objekt"],
          1 => ["flera objekt"]
        }
      }

      result = Output.format_json(message)
      decoded = JSON.decode!(result)

      assert decoded["msgid"] == "item"
      # For plural messages, JSON output returns the first form
      assert decoded["msgstr"] == "ett objekt"
    end
  end

  describe "to_map/1" do
    test "converts simple message to map" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"]
      }

      result = Output.to_map(message)

      assert result == %{msgid: "Hello", msgstr: "Hej"}
    end

    test "includes references in map" do
      message = %Message.Singular{
        msgid: ["Sign In"],
        msgstr: [""],
        references: [[{"lib/auth.ex", 12}]]
      }

      result = Output.to_map(message)

      assert result.msgid == "Sign In"
      assert result.msgstr == ""
      assert result.references == ["lib/auth.ex:12"]
    end

    test "includes comments in map" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"],
        comments: ["# Comment"]
      }

      result = Output.to_map(message)

      assert result.comments == ["# Comment"]
    end

    test "includes flags in map" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"],
        flags: [["fuzzy"]]
      }

      result = Output.to_map(message)

      assert result.flags == [["fuzzy"]]
    end

    test "handles empty references list" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"],
        references: []
      }

      result = Output.to_map(message)

      refute Map.has_key?(result, :references)
    end

    test "handles nil references" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"],
        references: nil
      }

      result = Output.to_map(message)

      refute Map.has_key?(result, :references)
    end
  end

  describe "print_message/2" do
    test "prints text format to stdout" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"]
      }

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Output.print_message(message, :text)
        end)

      assert output =~ "msgid \"Hello\""
      assert output =~ "msgstr \"Hej\""
    end

    test "prints JSON format to stdout" do
      message = %Message.Singular{
        msgid: ["Hello"],
        msgstr: ["Hej"]
      }

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Output.print_message(message, :json)
        end)

      decoded = JSON.decode!(String.trim(output))
      assert decoded["msgid"] == "Hello"
      assert decoded["msgstr"] == "Hej"
    end
  end

  describe "print_messages/2" do
    test "prints multiple messages in text format with separator" do
      messages = [
        %Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]},
        %Message.Singular{msgid: ["Goodbye"], msgstr: ["Hejdå"]}
      ]

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Output.print_messages(messages, :text)
        end)

      assert output =~ "msgid \"Hello\""
      assert output =~ "msgstr \"Hej\""
      assert output =~ "msgid \"Goodbye\""
      assert output =~ "msgstr \"Hejdå\""
    end

    test "prints multiple messages in JSON format (line-delimited)" do
      messages = [
        %Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]},
        %Message.Singular{msgid: ["Goodbye"], msgstr: ["Hejdå"]}
      ]

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Output.print_messages(messages, :json)
        end)

      lines = String.split(String.trim(output), "\n")
      assert length(lines) == 2

      decoded1 = JSON.decode!(Enum.at(lines, 0))
      assert decoded1["msgid"] == "Hello"
      assert decoded1["msgstr"] == "Hej"

      decoded2 = JSON.decode!(Enum.at(lines, 1))
      assert decoded2["msgid"] == "Goodbye"
      assert decoded2["msgstr"] == "Hejdå"
    end

    test "prints empty list without errors" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Output.print_messages([], :text)
        end)

      assert output == ""

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Output.print_messages([], :json)
        end)

      assert output == ""
    end
  end

  describe "integration with real .po files" do
    test "round-trip: parse → format_text matches .po format" do
      # This test verifies that formatting matches the original .po format
      po_file = Path.join([__DIR__, "..", "fixtures", "test.po"])

      {:ok, messages} = GettextOps.Parser.parse_file(po_file)

      # Format first message and verify it looks like .po format
      first_message = List.first(messages)

      if first_message do
        text_output = Output.format_text(first_message)
        assert text_output =~ ~r/msgid ".+"/
        assert text_output =~ ~r/msgstr ".+"/
      end
    end

    test "formats all fixture messages as JSON successfully" do
      po_file = Path.join([__DIR__, "..", "fixtures", "test.po"])

      {:ok, messages} = GettextOps.Parser.parse_file(po_file)

      # Verify all messages can be formatted as JSON
      Enum.each(messages, fn message ->
        json_output = Output.format_json(message)
        assert is_binary(json_output)

        # Verify it's valid JSON
        decoded = JSON.decode!(json_output)
        assert is_map(decoded)
        assert Map.has_key?(decoded, "msgid")
        assert Map.has_key?(decoded, "msgstr")
      end)
    end
  end
end
