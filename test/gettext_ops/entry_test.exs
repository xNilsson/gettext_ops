defmodule GettextOps.EntryTest do
  use ExUnit.Case, async: true
  doctest GettextOps.Entry

  alias GettextOps.Entry

  describe "untranslated?/1" do
    test "returns true for empty msgstr" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: [""]}
      assert Entry.untranslated?(message)
    end

    test "returns true for whitespace-only msgstr" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["  "]}
      assert Entry.untranslated?(message)
    end

    test "returns false for translated message" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      refute Entry.untranslated?(message)
    end

    test "returns true for empty plural forms" do
      message = %Expo.Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgstr: %{0 => [""], 1 => [""]}
      }

      assert Entry.untranslated?(message)
    end

    test "returns false for translated plural forms" do
      message = %Expo.Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgstr: %{0 => ["ett objekt"], 1 => ["objekt"]}
      }

      refute Entry.untranslated?(message)
    end

    test "returns true for empty list msgstr" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: []}
      assert Entry.untranslated?(message)
    end
  end

  describe "get_msgid/1" do
    test "returns msgid as string for simple message" do
      message = %Expo.Message.Singular{msgid: ["Hello"]}
      assert Entry.get_msgid(message) == "Hello"
    end

    test "joins multi-line msgid" do
      message = %Expo.Message.Singular{msgid: ["Welcome to\\n", "our app"]}
      assert Entry.get_msgid(message) == "Welcome to\\nour app"
    end

    test "handles plural msgid" do
      message = %Expo.Message.Plural{msgid: ["Hello"], msgid_plural: ["Hellos"]}
      assert Entry.get_msgid(message) == "Hello"
    end
  end

  describe "get_msgstr/1" do
    test "returns msgstr as string for simple message" do
      message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Hej"]}
      assert Entry.get_msgstr(message) == "Hej"
    end

    test "joins multi-line msgstr" do
      message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till\\n", "vår app"]}
      assert Entry.get_msgstr(message) == "Välkommen till\\nvår app"
    end

    test "returns first plural form for plural messages" do
      message = %Expo.Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgstr: %{0 => ["ett objekt"], 1 => ["objekt"]}
      }

      assert Entry.get_msgstr(message) == "ett objekt"
    end

    test "returns empty string for missing plural form 0" do
      message = %Expo.Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgstr: %{1 => ["objekt"]}
      }

      assert Entry.get_msgstr(message) == ""
    end

    test "returns empty string for empty msgstr" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: []}
      assert Entry.get_msgstr(message) == ""
    end
  end

  describe "matches_msgid?/2" do
    test "matches exact string" do
      message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      assert Entry.matches_msgid?(message, "Welcome to Phoenix!")
    end

    test "does not match partial string" do
      message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      refute Entry.matches_msgid?(message, "Welcome")
    end

    test "matches regex pattern" do
      message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      assert Entry.matches_msgid?(message, ~r/Phoenix/)
    end

    test "does not match non-matching regex" do
      message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      refute Entry.matches_msgid?(message, ~r/Django/)
    end

    test "matches case-insensitive regex" do
      message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      assert Entry.matches_msgid?(message, ~r/phoenix/i)
    end
  end

  describe "matches_msgstr?/2" do
    test "matches exact string" do
      message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till Phoenix!"]}
      assert Entry.matches_msgstr?(message, "Välkommen till Phoenix!")
    end

    test "does not match partial string" do
      message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till Phoenix!"]}
      refute Entry.matches_msgstr?(message, "Välkommen")
    end

    test "matches regex pattern" do
      message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till Phoenix!"]}
      assert Entry.matches_msgstr?(message, ~r/Phoenix/)
    end

    test "does not match non-matching regex" do
      message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till Phoenix!"]}
      refute Entry.matches_msgstr?(message, ~r/Django/)
    end
  end

  describe "get_domain/1" do
    test "returns default for message with references" do
      message = %Expo.Message.Singular{
        msgid: ["Hello"],
        references: [[{"lib/app_web/live/page_live.ex", 10}]]
      }

      assert Entry.get_domain(message) == "default"
    end

    test "returns default for message without references" do
      message = %Expo.Message.Singular{msgid: ["Hello"], references: []}
      assert Entry.get_domain(message) == "default"
    end
  end

  describe "update_msgstr/1" do
    test "updates msgstr for a message" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: [""]}
      updated = Entry.update_msgstr(message, "Hej")

      assert updated.msgstr == ["Hej"]
      assert updated.msgid == ["Hello"]
    end

    test "replaces existing msgstr" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Old"]}
      updated = Entry.update_msgstr(message, "New")

      assert updated.msgstr == ["New"]
    end
  end

  describe "update_msgid/1" do
    test "updates msgid for a message" do
      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      updated = Entry.update_msgid(message, "Hi")

      assert updated.msgid == ["Hi"]
      assert updated.msgstr == ["Hej"]
    end

    test "replaces existing msgid" do
      message = %Expo.Message.Singular{msgid: ["Old"], msgstr: ["Translation"]}
      updated = Entry.update_msgid(message, "New")

      assert updated.msgid == ["New"]
    end
  end
end
