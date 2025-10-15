defmodule GettextOps.Parser do
  @moduledoc """
  Wrapper module for parsing .po files using the Expo library.

  This module provides a simplified API for reading and filtering .po file entries,
  abstracting away the details of working directly with Expo.
  """

  alias GettextOps.Entry
  alias Expo.Message

  @doc """
  Parses a .po file and returns the messages.

  Returns `{:ok, messages}` on success or `{:error, reason}` on failure.

  ## Examples

      # Success case
      GettextOps.Parser.parse_file("test/fixtures/test.po")
      # => {:ok, [%Expo.Message.Singular{msgid: ["Welcome to Phoenix!"], msgstr: ["Välkommen till Phoenix!"]}, ...]}

      # Error case - file not found
      GettextOps.Parser.parse_file("nonexistent.po")
      # => {:error, :enoent}

  """
  @spec parse_file(String.t()) :: {:ok, [Message.t()]} | {:error, term()}
  def parse_file(path) when is_binary(path) do
    case Expo.PO.parse_file(path) do
      {:ok, %Expo.Messages{messages: messages}} ->
        {:ok, messages}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a .po file and filters messages using the provided predicate function.

  The filter function receives a message and should return a boolean.

  ## Examples

      # Filter for untranslated messages
      filter_fn = fn msg -> GettextOps.Entry.untranslated?(msg) end
      GettextOps.Parser.parse_and_filter("test/fixtures/empty.po", filter_fn)
      # => {:ok, [%Expo.Message.Singular{msgid: ["Profile settings"], msgstr: [""]}, ...]}

  """
  @spec parse_and_filter(String.t(), (Message.t() -> boolean())) ::
          {:ok, [Message.t()]} | {:error, term()}
  def parse_and_filter(path, filter_fn) when is_binary(path) and is_function(filter_fn, 1) do
    case parse_file(path) do
      {:ok, messages} ->
        filtered = Enum.filter(messages, filter_fn)
        {:ok, filtered}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a .po file and returns only untranslated messages.

  This is a convenience function equivalent to using `parse_and_filter/2`
  with `GettextOps.Entry.untranslated?/1`.

  ## Examples

      # Get all untranslated messages
      GettextOps.Parser.parse_untranslated("test/fixtures/empty.po")
      # => {:ok, [%Expo.Message.Singular{msgid: ["Profile settings"], msgstr: [""]}, ...]}

  """
  @spec parse_untranslated(String.t()) :: {:ok, [Message.t()]} | {:error, term()}
  def parse_untranslated(path) do
    parse_and_filter(path, &Entry.untranslated?/1)
  end

  @doc """
  Parses a .po file and searches for messages matching the given pattern in msgid.

  Pattern can be a string (exact match) or a regex.

  ## Examples

      # Search for messages containing "Welcome"
      GettextOps.Parser.search_msgid("test/fixtures/test.po", ~r/Welcome/)
      # => {:ok, [%Expo.Message.Singular{msgid: ["Welcome to Phoenix!"]}, ...]}

  """
  @spec search_msgid(String.t(), String.t() | Regex.t()) ::
          {:ok, [Message.t()]} | {:error, term()}
  def search_msgid(path, pattern) do
    parse_and_filter(path, &Entry.matches_msgid?(&1, pattern))
  end

  @doc """
  Parses a .po file and searches for messages matching the given pattern in msgstr.

  Pattern can be a string (exact match) or a regex.

  ## Examples

      # Search for messages with Swedish translation
      GettextOps.Parser.search_msgstr("test/fixtures/test.po", ~r/Välkommen/)
      # => {:ok, [%Expo.Message.Singular{msgid: ["Welcome to Phoenix!"], msgstr: ["Välkommen till Phoenix!"]}, ...]}

  """
  @spec search_msgstr(String.t(), String.t() | Regex.t()) ::
          {:ok, [Message.t()]} | {:error, term()}
  def search_msgstr(path, pattern) do
    parse_and_filter(path, &Entry.matches_msgstr?(&1, pattern))
  end

  @doc """
  Parses a .po file and returns the full Expo.Messages struct.

  This gives access to the complete PO file structure including headers.

  ## Examples

      # Get full structure including headers
      GettextOps.Parser.parse_file_full("test/fixtures/test.po")
      # => {:ok, %Expo.Messages{headers: [...], messages: [...]}}

  """
  @spec parse_file_full(String.t()) :: {:ok, Expo.Messages.t()} | {:error, term()}
  def parse_file_full(path) when is_binary(path) do
    Expo.PO.parse_file(path)
  end
end
