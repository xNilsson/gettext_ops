defmodule GettextOps.Writer do
  @moduledoc """
  Module for updating and writing .po files.

  This module provides functions for safely updating .po files while preserving
  structure, comments, and formatting using the Expo library.
  """

  alias GettextOps.Entry
  alias GettextOps.Parser
  alias Expo.Message

  @doc """
  Updates messages in a .po file using a transformation function.

  The update function receives a message and should return the updated message.
  The original file structure, headers, and comments are preserved.

  ## Examples

      # Update all message translations
      update_fn = fn msg -> %{msg | msgstr: ["Updated"]} end
      GettextOps.Writer.update_file("path/to/file.po", update_fn)
      # => :ok

  """
  @spec update_file(String.t(), (Message.t() -> Message.t())) :: :ok | {:error, term()}
  def update_file(path, update_fn) when is_binary(path) and is_function(update_fn, 1) do
    with {:ok, po_messages} <- Parser.parse_file_full(path),
         updated_messages = update_messages(po_messages.messages, update_fn),
         updated_po = %{po_messages | messages: updated_messages},
         iodata = Expo.PO.compose(updated_po),
         :ok <- File.write(path, iodata) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates specific translations in a .po file.

  Accepts a map of `msgid => msgstr` and updates matching messages.
  Returns `{:ok, %{updated: count}}` with the number of updated messages.

  ## Examples

      # Update multiple translations
      translations = %{"Hello" => "Hej", "Goodbye" => "Hejdå"}
      GettextOps.Writer.update_translations("path/to/file.po", translations)
      # => {:ok, %{updated: 2}}

  """
  @spec update_translations(String.t(), %{String.t() => String.t()}) ::
          {:ok, %{updated: integer()}} | {:error, term()}
  def update_translations(path, translations) when is_binary(path) and is_map(translations) do
    updated_count = :counters.new(1, [:atomics])

    update_fn = fn message ->
      msgid = Entry.get_msgid(message)

      case Map.get(translations, msgid) do
        nil ->
          message

        new_msgstr ->
          :counters.add(updated_count, 1, 1)
          Entry.update_msgstr(message, new_msgstr)
      end
    end

    case update_file(path, update_fn) do
      :ok ->
        count = :counters.get(updated_count, 1)
        {:ok, %{updated: count}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Changes all occurrences of a msgid to a new msgid in a .po file.

  This is useful for refactoring translation keys across the codebase.
  Returns `{:ok, %{updated: count}}` with the number of updated messages.

  ## Examples

      # Rename a translation key
      GettextOps.Writer.change_msgid("path/to/file.po", "Old text", "New text")
      # => {:ok, %{updated: 1}}

  """
  @spec change_msgid(String.t(), String.t(), String.t()) ::
          {:ok, %{updated: integer()}} | {:error, atom() | Exception.t()}
  def change_msgid(path, old_msgid, new_msgid)
      when is_binary(path) and is_binary(old_msgid) and is_binary(new_msgid) do
    updated_count = :counters.new(1, [:atomics])

    update_fn = fn message ->
      msgid = Entry.get_msgid(message)

      if msgid == old_msgid do
        :counters.add(updated_count, 1, 1)
        Entry.update_msgid(message, new_msgid)
      else
        message
      end
    end

    case update_file(path, update_fn) do
      :ok ->
        count = :counters.get(updated_count, 1)
        {:ok, %{updated: count}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Writes a new .po file with the given messages.

  Creates a new .po file from scratch with the provided messages.
  Optionally accepts headers as a list of strings.

  ## Examples

      # Create a new .po file
      messages = [%Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}]
      GettextOps.Writer.write_file("/tmp/new.po", messages)
      # => :ok

  """
  @spec write_file(String.t(), [Message.t()], [String.t()]) :: :ok | {:error, term()}
  def write_file(path, messages, headers \\ default_headers())
      when is_binary(path) and is_list(messages) and is_list(headers) do
    po_messages = %Expo.Messages{
      headers: headers,
      messages: messages
    }

    iodata = Expo.PO.compose(po_messages)
    File.write(path, iodata)
  end

  # Private functions

  defp update_messages(messages, update_fn) do
    Enum.map(messages, update_fn)
  end

  defp default_headers do
    [
      "## `msgid`s in this file are extracted from the source code.",
      "## Run `mix gettext.extract` to update this file."
    ]
  end
end
