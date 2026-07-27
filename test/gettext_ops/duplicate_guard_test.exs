defmodule GettextOps.DuplicateGuardTest do
  @moduledoc """
  A .po file holding two entries with the same `{msgctxt, msgid}` identity
  cannot be read back — `Expo.PO.parse_file!/1` raises
  `Expo.PO.DuplicateMessagesError`, which breaks compilation of the whole
  consuming application. Every write path must refuse to produce one.
  """

  use ExUnit.Case, async: false

  alias GettextOps.Operations.ChangeMsgid
  alias GettextOps.Writer

  @header ~s|msgid ""\nmsgstr ""\n"Language: sv\\n"\n\n|

  setup do
    base = Path.join(System.tmp_dir!(), "gettext_ops_dup_#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join([base, "sv", "LC_MESSAGES"]))

    on_exit(fn -> File.rm_rf!(base) end)

    %{base: base}
  end

  defp write_po(path, body) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, @header <> body)
    path
  end

  describe "Writer.check_duplicates/1" do
    test "accepts entries sharing a msgid but differing in msgctxt" do
      messages = [
        %Expo.Message.Singular{msgid: ["Active"]},
        %Expo.Message.Singular{msgid: ["Active"], msgctxt: ["token status"]}
      ]

      assert Writer.check_duplicates(messages) == :ok
    end

    test "rejects two entries with the same identity and names them" do
      messages = [
        %Expo.Message.Singular{msgid: ["Active"], msgctxt: ["token status"]},
        %Expo.Message.Singular{msgid: ["Active"], msgctxt: ["token status"]}
      ]

      assert {:error, reason} = Writer.check_duplicates(messages)
      assert reason =~ "duplicate"
      assert reason =~ ~s(msgctxt "token status")
      assert reason =~ ~s(msgid "Active")
    end

    test "treats a missing and an empty msgctxt as the same identity" do
      messages = [
        %Expo.Message.Singular{msgid: ["Active"], msgctxt: nil},
        %Expo.Message.Singular{msgid: ["Active"], msgctxt: [""]}
      ]

      assert {:error, _} = Writer.check_duplicates(messages)
    end
  end

  describe "Writer.change_msgid/3" do
    test "refuses a rename that would collide with an existing msgid", %{base: base} do
      path =
        write_po(
          Path.join(base, "w.po"),
          ~s|msgid "Actve"\nmsgstr "a"\n\nmsgid "Active"\nmsgstr "b"\n|
        )

      original = File.read!(path)

      assert {:error, reason} = Writer.change_msgid(path, "Actve", "Active")
      assert reason =~ "duplicate"

      # File untouched, and still readable
      assert File.read!(path) == original
      assert %Expo.Messages{} = Expo.PO.parse_file!(path)
    end

    test "renames every context variant of a msgid", %{base: base} do
      path =
        write_po(
          Path.join(base, "w.po"),
          ~s|msgid "Actve"\nmsgstr "a"\n\nmsgctxt "token status"\nmsgid "Actve"\nmsgstr "b"\n|
        )

      assert {:ok, %{updated: 2}} = Writer.change_msgid(path, "Actve", "Active")

      msgids = Expo.PO.parse_file!(path).messages |> Enum.map(&GettextOps.Entry.key/1)
      assert msgids == [{nil, "Active"}, {"token status", "Active"}]
    end
  end

  describe "Writer.update_translations/2" do
    test "a bare msgid updates only the contextless entry", %{base: base} do
      path =
        write_po(
          Path.join(base, "w.po"),
          ~s|msgid "Active"\nmsgstr "Aktiv"\n\nmsgctxt "token status"\nmsgid "Active"\nmsgstr "Giltig"\n|
        )

      assert {:ok, %{updated: 1}} = Writer.update_translations(path, %{"Active" => "Påslagen"})

      entries =
        Expo.PO.parse_file!(path).messages
        |> Map.new(fn m -> {GettextOps.Entry.key(m), GettextOps.Entry.get_msgstr(m)} end)

      assert entries[{nil, "Active"}] == "Påslagen"
      assert entries[{"token status", "Active"}] == "Giltig"
    end

    test "a {msgctxt, msgid} key targets the context-carrying entry", %{base: base} do
      path =
        write_po(
          Path.join(base, "w.po"),
          ~s|msgid "Active"\nmsgstr "Aktiv"\n\nmsgctxt "token status"\nmsgid "Active"\nmsgstr "Giltig"\n|
        )

      assert {:ok, %{updated: 1}} =
               Writer.update_translations(path, %{{"token status", "Active"} => "Godkänd"})

      entries =
        Expo.PO.parse_file!(path).messages
        |> Map.new(fn m -> {GettextOps.Entry.key(m), GettextOps.Entry.get_msgstr(m)} end)

      assert entries[{nil, "Active"}] == "Aktiv"
      assert entries[{"token status", "Active"}] == "Godkänd"
    end
  end

  describe "Operations.ChangeMsgid.update_file/4" do
    test "refuses a rename that would collide with an existing msgid", %{base: base} do
      path =
        write_po(
          Path.join([base, "sv", "LC_MESSAGES", "default.po"]),
          ~s|msgid "Actve"\nmsgstr "Aktiv"\n\nmsgid "Active"\nmsgstr "Redan aktiv"\n|
        )

      original = File.read!(path)

      assert {:error, reason} = ChangeMsgid.update_file(path, "Actve", "Active")
      assert reason =~ "duplicate"

      assert File.read!(path) == original
      assert %Expo.Messages{} = Expo.PO.parse_file!(path)
    end

    test "still performs a rename that collides with nothing", %{base: base} do
      path =
        write_po(
          Path.join([base, "sv", "LC_MESSAGES", "default.po"]),
          ~s|msgid "Actve"\nmsgstr "Aktiv"\n|
        )

      assert {:ok, 1, "Aktiv"} = ChangeMsgid.update_file(path, "Actve", "Active")
      assert Expo.PO.parse_file!(path).messages |> Enum.map(& &1.msgid) == [["Active"]]
    end
  end
end
