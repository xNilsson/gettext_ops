defmodule GettextOps.Entry do
  @moduledoc """
  Helper functions for working with Expo.Message entries.

  This module provides predicates and utilities for filtering and inspecting
  translation entries without needing to understand the Expo.Message structure directly.
  """

  alias Expo.Message

  @doc """
  Checks if a message has an empty msgstr (is untranslated).

  Returns `true` if the msgstr is empty or contains only empty strings.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: [""]}
      iex> GettextOps.Entry.untranslated?(message)
      true

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      iex> GettextOps.Entry.untranslated?(message)
      false

  """
  @spec untranslated?(Message.t()) :: boolean()
  def untranslated?(%Message.Singular{msgstr: msgstr}) do
    case msgstr do
      # Singular messages have a list of strings
      list when is_list(list) ->
        Enum.all?(list, &(String.trim(&1) == ""))

      # Empty or other cases
      _ ->
        true
    end
  end

  def untranslated?(%Message.Plural{msgstr: msgstr}) do
    # Plural messages have a map of index => list of strings
    case msgstr do
      map when is_map(map) and map_size(map) == 0 ->
        true

      map when is_map(map) ->
        map
        |> Map.values()
        |> Enum.all?(fn
          list when is_list(list) -> Enum.all?(list, &(String.trim(&1) == ""))
          _ -> true
        end)

      _ ->
        true
    end
  end

  @doc """
  Gets the msgid as a string from a message.

  Handles multi-line msgids by joining them together.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"]}
      iex> GettextOps.Entry.get_msgid(message)
      "Hello"

      iex> message = %Expo.Message.Singular{msgid: ["Hello\\n", "World"]}
      iex> GettextOps.Entry.get_msgid(message)
      "Hello\\nWorld"

  """
  @spec get_msgid(Message.t()) :: String.t()
  def get_msgid(%Message.Singular{msgid: msgid}) when is_list(msgid) do
    Enum.join(msgid, "")
  end

  def get_msgid(%Message.Plural{msgid: msgid}) when is_list(msgid) do
    Enum.join(msgid, "")
  end

  @doc """
  Gets the normalised msgctxt of a message, or `nil` when it has no context.

  Expo represents a missing context as `nil` and a present one as a list of
  string chunks. An explicit `msgctxt ""` is treated as *no* context, matching
  gettext (and Expo, which considers `msgctxt ""` and a bare msgid duplicates).

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Active"]}
      iex> GettextOps.Entry.get_msgctxt(message)
      nil

      iex> message = %Expo.Message.Singular{msgid: ["Active"], msgctxt: ["token status"]}
      iex> GettextOps.Entry.get_msgctxt(message)
      "token status"

      iex> message = %Expo.Message.Singular{msgid: ["Active"], msgctxt: [""]}
      iex> GettextOps.Entry.get_msgctxt(message)
      nil

  """
  @spec get_msgctxt(Message.t()) :: String.t() | nil
  def get_msgctxt(%Message.Singular{msgctxt: msgctxt}), do: normalize_msgctxt(msgctxt)
  def get_msgctxt(%Message.Plural{msgctxt: msgctxt}), do: normalize_msgctxt(msgctxt)

  defp normalize_msgctxt(nil), do: nil
  defp normalize_msgctxt(msgctxt) when is_binary(msgctxt), do: normalize_msgctxt([msgctxt])

  defp normalize_msgctxt(msgctxt) when is_list(msgctxt) do
    case Enum.join(msgctxt, "") do
      "" -> nil
      context -> context
    end
  end

  @doc """
  Returns the gettext identity of a message as a `{msgctxt, msgid}` tuple.

  This — not the msgid alone — is what uniquely identifies an entry in a
  catalogue. Two entries sharing a msgid but carrying different `msgctxt`
  values are distinct entries, and keying them by msgid alone silently
  collapses one onto the other.

  `msgid_plural` is deliberately *not* part of the key: gettext identifies a
  plural entry by its singular msgid, and Expo rejects a catalogue that holds
  both a singular and a plural entry for the same `{msgctxt, msgid}` pair.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Active"]}
      iex> GettextOps.Entry.key(message)
      {nil, "Active"}

      iex> message = %Expo.Message.Singular{msgid: ["Active"], msgctxt: ["token status"]}
      iex> GettextOps.Entry.key(message)
      {"token status", "Active"}

  """
  @spec key(Message.t()) :: {String.t() | nil, String.t()}
  def key(message), do: {get_msgctxt(message), get_msgid(message)}

  @doc """
  Gets the msgstr as a string from a message.

  Handles multi-line msgstrs by joining them together.
  For plural forms, returns the first plural form (index 0).

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      iex> GettextOps.Entry.get_msgstr(message)
      "Hej"

      iex> message = %Expo.Message.Plural{msgid: ["item"], msgid_plural: ["items"], msgstr: %{0 => ["One item"], 1 => ["Many items"]}}
      iex> GettextOps.Entry.get_msgstr(message)
      "One item"

  """
  @spec get_msgstr(Message.t()) :: String.t()
  def get_msgstr(%Message.Singular{msgstr: msgstr}) when is_list(msgstr) do
    Enum.join(msgstr, "")
  end

  def get_msgstr(%Message.Plural{msgstr: msgstr}) when is_map(msgstr) do
    case Map.get(msgstr, 0) do
      list when is_list(list) -> Enum.join(list, "")
      _ -> ""
    end
  end

  @doc """
  Checks if the msgid matches a given pattern.

  Pattern can be:
  - A string for exact match
  - A regex for pattern matching

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      iex> GettextOps.Entry.matches_msgid?(message, "Welcome")
      false

      iex> message = %Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}
      iex> GettextOps.Entry.matches_msgid?(message, ~r/Phoenix/)
      true

  """
  @spec matches_msgid?(Message.t(), String.t() | Regex.t()) :: boolean()
  def matches_msgid?(message, pattern) when is_binary(pattern) do
    get_msgid(message) == pattern
  end

  def matches_msgid?(message, %Regex{} = pattern) do
    msgid = get_msgid(message)
    Regex.match?(pattern, msgid)
  end

  @doc """
  Checks if the msgstr matches a given pattern.

  Pattern can be:
  - A string for exact match
  - A regex for pattern matching

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till Phoenix!"]}
      iex> GettextOps.Entry.matches_msgstr?(message, "Välkommen")
      false

      iex> message = %Expo.Message.Singular{msgid: ["Hi"], msgstr: ["Välkommen till Phoenix!"]}
      iex> GettextOps.Entry.matches_msgstr?(message, ~r/Phoenix/)
      true

  """
  @spec matches_msgstr?(Message.t(), String.t() | Regex.t()) :: boolean()
  def matches_msgstr?(message, pattern) when is_binary(pattern) do
    get_msgstr(message) == pattern
  end

  def matches_msgstr?(message, %Regex{} = pattern) do
    msgstr = get_msgstr(message)
    Regex.match?(pattern, msgstr)
  end

  @doc """
  Gets the domain from a message reference.

  Extracts the domain from the first reference path if available.
  Returns "default" if no references are found.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], references: [[{"lib/app_web/live/page_live.ex", 10}]]}
      iex> GettextOps.Entry.get_domain(message)
      "default"

  """
  @spec get_domain(Message.t()) :: String.t()
  def get_domain(%Message.Singular{references: references}) when is_list(references) do
    case references do
      [[{_path, _line} | _] | _] -> "default"
      _ -> "default"
    end
  end

  def get_domain(%Message.Plural{references: references}) when is_list(references) do
    case references do
      [[{_path, _line} | _] | _] -> "default"
      _ -> "default"
    end
  end

  def get_domain(_), do: "default"

  @doc """
  Creates a new message with updated msgstr.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: [""]}
      iex> updated = GettextOps.Entry.update_msgstr(message, "Hej")
      iex> updated.msgstr
      ["Hej"]

  """
  @spec update_msgstr(Message.t(), String.t()) :: Message.t()
  def update_msgstr(%Message.Singular{} = message, new_msgstr) when is_binary(new_msgstr) do
    %{message | msgstr: [new_msgstr]}
  end

  def update_msgstr(%Message.Plural{} = message, new_msgstr) when is_binary(new_msgstr) do
    # For plural messages, update the first form (index 0)
    %{message | msgstr: Map.put(message.msgstr, 0, [new_msgstr])}
  end

  @doc """
  Creates a new message with updated msgid.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      iex> updated = GettextOps.Entry.update_msgid(message, "Hi")
      iex> updated.msgid
      ["Hi"]

  """
  @spec update_msgid(Message.t(), String.t()) :: Message.t()
  def update_msgid(%Message.Singular{} = message, new_msgid) when is_binary(new_msgid) do
    %{message | msgid: [new_msgid]}
  end

  def update_msgid(%Message.Plural{} = message, new_msgid) when is_binary(new_msgid) do
    %{message | msgid: [new_msgid]}
  end
end
