defmodule GettextOps.Operations.TranslateMsgctxtTest do
  @moduledoc """
  Regression tests for msgctxt-aware entry identity in `translate`.

  Gettext identifies an entry by the pair `{msgctxt, msgid}`, not by msgid
  alone. Keying by msgid alone made `translate` collapse every entry that
  shared a msgid onto whichever duplicate happened to win, rewriting entries
  the caller never asked to touch and producing a .po file that
  `Expo.PO.parse_file!/1` refuses to read.
  """

  use ExUnit.Case, async: false

  alias GettextOps.Entry
  alias GettextOps.Operations.Translate

  setup_all do
    Application.put_env(:gettext_ops, :gettext_path, "test/fixtures/gettext")
    :ok
  end

  setup do
    test_locale = "sv_ctx_#{System.unique_integer([:positive])}"
    test_dir = Path.join(["test/fixtures/gettext", test_locale, "LC_MESSAGES"])
    File.mkdir_p!(test_dir)

    test_file = Path.join(test_dir, "default.po")
    File.cp!("test/fixtures/msgctxt.po", test_file)

    on_exit(fn ->
      File.rm_rf!("test/fixtures/gettext/#{test_locale}")
    end)

    %{test_locale: test_locale, test_file: test_file}
  end

  # Returns {msgctxt, msgid} => msgstr for every entry in the file.
  defp read_entries(path) do
    path
    |> Expo.PO.parse_file!()
    |> Map.fetch!(:messages)
    |> Map.new(fn msg -> {Entry.key(msg), Entry.get_msgstr(msg)} end)
  end

  describe "translating an unrelated msgid" do
    test "leaves context-disambiguated entries intact and distinct", %{
      test_locale: locale,
      test_file: test_file
    } do
      before = read_entries(test_file)

      # "Sign In" has nothing to do with "Active" — translating it must not
      # touch any other entry in the catalogue.
      {:ok, result} = Translate.run(%{"Sign In" => "Logga in"}, locale: locale)

      assert result.updated == 1
      assert result.not_found == []

      # The file must still be readable. Before the fix this raised
      # Expo.PO.DuplicateMessagesError.
      after_ = read_entries(test_file)

      assert after_[{nil, "Sign In"}] == "Logga in"

      # Every other entry is byte-for-byte what it was.
      assert Map.delete(after_, {nil, "Sign In"}) == Map.delete(before, {nil, "Sign In"})

      # Spelled out, because this is the exact corruption that was reported:
      assert after_[{nil, "Active"}] == "Aktiv"
      assert after_[{"token status", "Active"}] == "Giltig"
      assert after_[{"user status", "Active"}] == "Aktiverad"
      assert after_[{nil, "Open"}] == "Öppna"
      assert after_[{"verb", "Open"}] == "Öppna filen"
    end

    test "writes no duplicate {msgctxt, msgid} pairs", %{
      test_locale: locale,
      test_file: test_file
    } do
      {:ok, _} = Translate.run(%{"Sign In" => "Logga in"}, locale: locale)

      keys =
        test_file
        |> Expo.PO.parse_file!()
        |> Map.fetch!(:messages)
        |> Enum.map(&Entry.key/1)

      assert keys == Enum.uniq(keys)
      assert length(keys) == 7
    end

    test "preserves a context-carrying plural entry unchanged", %{
      test_locale: locale,
      test_file: test_file
    } do
      {:ok, _} = Translate.run(%{"Sign In" => "Logga in"}, locale: locale)

      plural =
        test_file
        |> Expo.PO.parse_file!()
        |> Map.fetch!(:messages)
        |> Enum.find(&(Entry.key(&1) == {"cart", "%{count} item"}))

      assert %Expo.Message.Plural{} = plural
      assert plural.msgid_plural == ["%{count} items"]
      assert plural.msgstr == %{0 => ["%{count} vara"], 1 => ["%{count} varor"]}
    end
  end

  describe "translating an ambiguous msgid" do
    test "updates the contextless entry and leaves contexted siblings alone", %{
      test_locale: locale,
      test_file: test_file
    } do
      {:ok, result} = Translate.run(%{"Active" => "Påslagen"}, locale: locale)

      assert result.updated == 1

      entries = read_entries(test_file)

      assert entries[{nil, "Active"}] == "Påslagen"
      assert entries[{"token status", "Active"}] == "Giltig"
      assert entries[{"user status", "Active"}] == "Aktiverad"
    end
  end

  describe "Entry.key/1" do
    test "distinguishes entries by msgctxt" do
      plain = %Expo.Message.Singular{msgid: ["Active"], msgstr: ["Aktiv"]}
      contexted = %Expo.Message.Singular{msgid: ["Active"], msgctxt: ["token status"]}

      assert Entry.key(plain) == {nil, "Active"}
      assert Entry.key(contexted) == {"token status", "Active"}
      refute Entry.key(plain) == Entry.key(contexted)
    end

    test "treats nil, empty list and empty string msgctxt as no context" do
      assert Entry.key(%Expo.Message.Singular{msgid: ["x"], msgctxt: nil}) == {nil, "x"}
      assert Entry.key(%Expo.Message.Singular{msgid: ["x"], msgctxt: []}) == {nil, "x"}
      assert Entry.key(%Expo.Message.Singular{msgid: ["x"], msgctxt: [""]}) == {nil, "x"}
    end

    test "joins multi-line msgctxt and msgid" do
      msg = %Expo.Message.Singular{msgid: ["Hello ", "world"], msgctxt: ["long ", "context"]}

      assert Entry.key(msg) == {"long context", "Hello world"}
    end

    test "keys plural messages the same way as singular ones" do
      # Gettext identity is {msgctxt, msgid}; msgid_plural is not part of it,
      # and Expo rejects a catalogue holding both forms of one msgid.
      singular = %Expo.Message.Singular{msgid: ["item"], msgctxt: ["cart"]}

      plural = %Expo.Message.Plural{
        msgid: ["item"],
        msgid_plural: ["items"],
        msgctxt: ["cart"],
        msgstr: %{0 => ["sak"]}
      }

      assert Entry.key(singular) == {"cart", "item"}
      assert Entry.key(plural) == {"cart", "item"}
    end
  end
end
