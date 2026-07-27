defmodule GettextOps.Output do
  @moduledoc """
  Output formatting functions for gettext messages.

  This module provides consistent formatting for both plain text (.po format)
  and JSON output. JSON output uses line-delimited format (one JSON object per line)
  for easy piping to LLMs and other tools.
  """

  alias Expo.Message
  alias GettextOps.Entry

  @doc """
  Formats a message as plain text in .po file format.

  Returns a string representation of the message that matches the .po file format,
  including msgid and msgstr lines.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Sign In"], msgstr: [""]}
      iex> GettextOps.Output.format_text(message)
      "msgid \\"Sign In\\"\\nmsgstr \\"\\"\\n"

      iex> message = %Expo.Message.Singular{msgid: ["Welcome"], msgstr: ["Välkommen"]}
      iex> GettextOps.Output.format_text(message)
      "msgid \\"Welcome\\"\\nmsgstr \\"Välkommen\\"\\n"

  """
  @spec format_text(Message.t()) :: String.t()
  def format_text(%Message.Singular{} = message) do
    msgid = Entry.get_msgid(message)
    msgstr = Entry.get_msgstr(message)

    msgctxt_line(message) <>
      """
      msgid "#{escape_string(msgid)}"
      msgstr "#{escape_string(msgstr)}"
      """
  end

  def format_text(%Message.Plural{} = message) do
    msgid = Entry.get_msgid(message)
    msgid_plural = message.msgid_plural |> Enum.join("")

    # Format plural forms
    msgstr_lines =
      message.msgstr
      |> Enum.sort_by(fn {index, _} -> index end)
      |> Enum.map(fn {index, str_list} ->
        str = Enum.join(str_list, "")
        "msgstr[#{index}] \"#{escape_string(str)}\""
      end)
      |> Enum.join("\n")

    msgctxt_line(message) <>
      """
      msgid "#{escape_string(msgid)}"
      msgid_plural "#{escape_string(msgid_plural)}"
      #{msgstr_lines}
      """
  end

  # A context-carrying entry is a different entry from a contextless one with
  # the same msgid, so the msgctxt has to be shown to tell them apart.
  defp msgctxt_line(message) do
    case Entry.get_msgctxt(message) do
      nil -> ""
      msgctxt -> ~s(msgctxt "#{escape_string(msgctxt)}"\n)
    end
  end

  @doc """
  Formats a message as JSON.

  Returns a JSON string (single line) containing msgid, msgstr, and optional
  references, comments, and flags.

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Sign In"], msgstr: [""]}
      iex> GettextOps.Output.format_json(message) |> JSON.decode!()
      %{"msgid" => "Sign In", "msgstr" => ""}

      # With references (JSON key order may vary):
      message = %Expo.Message.Singular{msgid: ["Welcome"], msgstr: ["Välkommen"], references: [[{"lib/home.ex", 5}]]}
      GettextOps.Output.format_json(message)
      # => JSON string containing: "msgid":"Welcome", "msgstr":"Välkommen", "references":["lib/home.ex:5"]

  """
  @spec format_json(Message.t()) :: String.t()
  def format_json(message) do
    message
    |> to_map()
    |> JSON.encode!()
  end

  @doc """
  Converts a message to a map for JSON encoding.

  The map includes:
  - `msgid`: The message ID
  - `msgstr`: The message string (for plurals, the first form)
  - `msgctxt`: The message context (only if the entry has one)
  - `references`: List of "file:line" strings (if present)
  - `comments`: List of comment strings (if present)
  - `flags`: List of flag strings (if present)

  ## Examples

      iex> message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      iex> GettextOps.Output.to_map(message)
      %{msgid: "Hello", msgstr: "Hej"}

      iex> message = %Expo.Message.Singular{
      ...>   msgid: ["Sign In"],
      ...>   msgstr: [""],
      ...>   references: [[{"lib/auth.ex", 12}]]
      ...> }
      iex> GettextOps.Output.to_map(message)
      %{msgid: "Sign In", msgstr: "", references: ["lib/auth.ex:12"]}

      iex> message = %Expo.Message.Singular{
      ...>   msgid: ["Active"],
      ...>   msgstr: ["Giltig"],
      ...>   msgctxt: ["token status"]
      ...> }
      iex> GettextOps.Output.to_map(message)
      %{msgid: "Active", msgstr: "Giltig", msgctxt: "token status"}

  """
  @spec to_map(Message.t()) :: map()
  def to_map(message) do
    base_map = %{
      msgid: Entry.get_msgid(message),
      msgstr: Entry.get_msgstr(message)
    }

    base_map
    |> add_msgctxt(message)
    |> add_references(message)
    |> add_comments(message)
    |> add_flags(message)
  end

  @doc """
  Prints a message to stdout in the specified format.

  ## Examples

      message = %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]}
      GettextOps.Output.print_message(message, :text)
      # Outputs: msgid "Hello"\\nmsgstr "Hej"\\n

      GettextOps.Output.print_message(message, :json)
      # Outputs: {"msgid":"Hello","msgstr":"Hej"}

  """
  @spec print_message(Message.t(), :text | :json) :: :ok
  def print_message(message, format) do
    case format do
      :text -> IO.write(format_text(message))
      :json -> IO.puts(format_json(message))
    end
  end

  @doc """
  Prints multiple messages with appropriate separator.

  For text format, adds a blank line between messages.
  For JSON format, outputs one JSON object per line (line-delimited JSON).

  ## Examples

      messages = [
        %Expo.Message.Singular{msgid: ["Hello"], msgstr: ["Hej"]},
        %Expo.Message.Singular{msgid: ["Goodbye"], msgstr: ["Hejdå"]}
      ]
      GettextOps.Output.print_messages(messages, :text)
      # Outputs: msgid "Hello"\\nmsgstr "Hej"\\n\\nmsgid "Goodbye"\\nmsgstr "Hejdå"\\n

      GettextOps.Output.print_messages(messages, :json)
      # Outputs: {"msgid":"Hello","msgstr":"Hej"}\\n{"msgid":"Goodbye","msgstr":"Hejdå"}

  """
  @spec print_messages([Message.t()], :text | :json) :: :ok
  def print_messages(messages, format) do
    case format do
      :text ->
        messages
        |> Enum.each(fn message ->
          IO.write(format_text(message))
          IO.write("\n")
        end)

      :json ->
        messages
        |> Enum.each(fn message ->
          IO.puts(format_json(message))
        end)
    end
  end

  # Private helper functions

  defp escape_string(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end

  defp add_msgctxt(map, message) do
    case Entry.get_msgctxt(message) do
      nil -> map
      msgctxt -> Map.put(map, :msgctxt, msgctxt)
    end
  end

  defp add_references(map, %Message.Singular{references: references}) do
    add_references_impl(map, references)
  end

  defp add_references(map, %Message.Plural{references: references}) do
    add_references_impl(map, references)
  end

  defp add_references_impl(map, references) when is_list(references) and length(references) > 0 do
    formatted_refs =
      references
      |> List.flatten()
      |> Enum.map(fn
        {file, line} when is_binary(file) and is_integer(line) ->
          "#{file}:#{line}"

        {file, line} when is_binary(file) ->
          "#{file}:#{line}"

        other ->
          inspect(other)
      end)

    if length(formatted_refs) > 0 do
      Map.put(map, :references, formatted_refs)
    else
      map
    end
  end

  defp add_references_impl(map, _), do: map

  defp add_comments(map, %Message.Singular{comments: comments}) do
    add_comments_impl(map, comments)
  end

  defp add_comments(map, %Message.Plural{comments: comments}) do
    add_comments_impl(map, comments)
  end

  defp add_comments_impl(map, comments) when is_list(comments) and length(comments) > 0 do
    Map.put(map, :comments, comments)
  end

  defp add_comments_impl(map, _), do: map

  defp add_flags(map, %Message.Singular{flags: flags}) do
    add_flags_impl(map, flags)
  end

  defp add_flags(map, %Message.Plural{flags: flags}) do
    add_flags_impl(map, flags)
  end

  defp add_flags_impl(map, flags) when is_list(flags) and length(flags) > 0 do
    Map.put(map, :flags, flags)
  end

  defp add_flags_impl(map, _), do: map
end
