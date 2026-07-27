# gettext_ops

> Targeted operations for Phoenix Gettext translations.
> Quick edits, bulk updates, and search for .po files.

**gettext_ops** provides Mix tasks for searching, listing, and updating Phoenix Gettext translation files without loading entire files into memory. Built on [Expo](https://hex.pm/packages/expo) for reliable .po file parsing.

## Why gettext_ops?

Working with large `.po` files (1000+ lines) is painful for both humans and AI coding agents:

- **Reading entire files wastes tokens** - LLMs consume thousands of tokens parsing files just to find a few entries
- **Manual editing is tedious** - Updating translations across multiple language files and source code references requires many repetitive edits
- **No quick overview** - Hard to see what needs translation without opening and scanning files

**gettext_ops solves this** with targeted operations:

```elixir
# List untranslated entries (no file reading needed!)
mix gettext_ops.list_untranslated --locale sv --json

# Search for specific translations
mix gettext_ops.search "Welcome" --locale sv

# Bulk update translations from a file
mix gettext_ops.translate translations.txt --locale sv

# Update all .po files at once and it's source text everywhere it appears
mix gettext_ops.change_msgid "Sign In" "Log In"
```

## Features

- 🎯 **Targeted queries** - Get only the entries you need, not entire files
- 📝 **Bulk operations** - Update multiple translations at once
- 🔄 **Global edits** - Change msgid across all language files and source code in one command
- 🤖 **LLM-friendly** - JSON output for easy parsing by AI tools
- ⚡ **Fast** - Built on Expo for reliable .po file handling
- 🔧 **Phoenix-native** - Works with standard `priv/gettext` structure

## Installation

Add `gettext_ops` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:gettext_ops, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

```bash
# List all untranslated entries for Swedish
mix gettext_ops.list_untranslated --locale sv

# Get JSON output (perfect for piping to other tools or LLMs)
mix gettext_ops.list_untranslated --locale sv --json

# Search for entries containing "Welcome"
mix gettext_ops.search "Welcome" --locale sv

# Apply translations (format: msgid = msgstr)
mix gettext_ops.translate --locale sv <<EOF
Sign In = Logga in
Sign Out = Logga ut
Welcome = Välkommen
EOF

# Change msgid "Sign In" to "Log In" everywhere (all .po files, .pot templates, and source code)
mix gettext_ops.change_msgid "Sign In" "Log In"
```

## Usage Examples

### Working with Untranslated Strings

```bash
# Show untranslated Swedish strings
mix gettext_ops.list_untranslated --locale sv --json --limit 10

# Check how many translations are missing
mix gettext_ops.list_untranslated --locale sv | wc -l

# Get entries ready for translation
mix gettext_ops.list_untranslated --locale sv --json --limit 20 > to_translate.json
```

**Token savings for AI agents**: Instead of reading a 5000-line .po file (consuming ~15k tokens), get exactly the 10 entries needed (~500 tokens).

### Searching Translations

```bash
# Find all login-related source strings (searches msgid)
mix gettext_ops.search "login" --locale sv --json

# Find error messages in source strings
mix gettext_ops.search "error" --locale en --json | jq .

# Search in translations (searches msgstr)
mix gettext_ops.search_value "Välkommen" --locale sv
```

### Bulk Translation Updates

```bash
# Apply translations from a file
mix gettext_ops.translate --locale sv translations.txt

# Apply translations from stdin
mix gettext_ops.translate --locale sv <<EOF
Sign In = Logga in
Sign Out = Logga ut
Welcome = Välkommen
EOF

# Batch translate with LLM assistance
mix gettext_ops.list_untranslated --locale sv --json --limit 20 | \
  llm "translate to Swedish" | \
  mix gettext_ops.translate --locale sv
```

### Changing Source Text

```bash
# Update msgid everywhere (all .po files, .pot templates, and source code references)
mix gettext_ops.change_msgid "Sign In" "Log In"

# Preview changes first
mix gettext_ops.change_msgid --dry-run "Sign In" "Log In"
```

## Development Workflow

### Typical Translation Process

```bash
# 1. Extract new strings from code
mix gettext.extract --merge

# 2. See what needs translation
mix gettext_ops.list_untranslated --locale sv

# 3. Translate (manually, with LLM, or with translation service)
mix gettext_ops.list_untranslated --locale sv --json --limit 10 | \
  your_translation_tool | \
  mix gettext_ops.translate --locale sv

# 4. Verify
mix gettext_ops.list_untranslated --locale sv
```

### Updating Copy

```bash
# 1. Find current usage
mix gettext_ops.search "Old Text" --json

# 2. Update msgid everywhere (keeps existing translations)
mix gettext_ops.change_msgid "Old Text" "New Text"

# 3. Re-extract from source code (updates references)
mix gettext.extract --merge
```

## Commands

### `mix gettext_ops.list_untranslated`

List all entries with empty translations (missing msgstr values). Use this to see what still needs translation.

**Options:**
- `--locale` / `-l` - Target locale (e.g., `sv`, `en`, `de`)
- `--domain` / `-d` - Gettext domain (default: `default`)
- `--json` - Output as line-delimited JSON
- `--limit` / `-n` - Limit number of results

**Examples:**

```bash
# Plain text output
mix gettext_ops.list_untranslated --locale sv

# JSON output (one entry per line)
mix gettext_ops.list_untranslated --locale sv --json

# First 10 untranslated entries
mix gettext_ops.list_untranslated --locale sv --limit 10
```

**Output format (plain text):**
```
msgid "Sign In"
msgstr ""

msgid "Sign Out"
msgstr ""
```

**Output format (JSON):**
```json
{"msgid":"Sign In","msgstr":"","references":["lib/my_app_web/controllers/auth_controller.ex:12"]}
{"msgid":"Sign Out","msgstr":"","references":["lib/my_app_web/controllers/auth_controller.ex:18"]}
```

---

### `mix gettext_ops.search`

Search for entries where **msgid** (source text) matches a pattern. Use this to find entries by their English/source strings.

**Options:**
- `--locale` / `-l` - Target locale
- `--domain` / `-d` - Gettext domain (default: `default`)
- `--regex` / `-r` - Use regex pattern (case-insensitive substring by default)
- `--json` - Output as JSON
- `--limit` / `-n` - Limit results

**Examples:**

```bash
# Find entries containing "Welcome"
mix gettext_ops.search "Welcome" --locale sv

# Regex search (entries starting with "Error")
mix gettext_ops.search "^Error" --locale sv --regex

# JSON output
mix gettext_ops.search "button" --locale sv --json
```

---

### `mix gettext_ops.search_value`

Search for entries where **msgstr** (translated text) matches a pattern. Use this to find entries by their translated strings.

**Options:** Same as `search`

**Examples:**

```bash
# Find Swedish translations containing "Välkommen"
mix gettext_ops.search_value "Välkommen" --locale sv

# Find all translations with "fel" (Swedish for error/wrong)
mix gettext_ops.search_value "fel" --locale sv --json
```

---

### `mix gettext_ops.translate`

Apply translations from a text file or stdin to .po files. This updates **msgstr** (translation values) for given msgids.

**Input format:**
```
msgid text = msgstr translation
msgid text = msgstr translation
```

**Options:**
- `--locale` / `-l` - Target locale (required)
- `--domain` / `-d` - Gettext domain (default: `default`)
- `--file` / `-f` - Input file (uses stdin if not provided)
- `--force` - Continue even if a msgid is not found or ambiguous (show warnings)

**Entries with a `msgctxt`**

Gettext identifies an entry by the pair `{msgctxt, msgid}`, so a catalogue can
hold several entries with the same msgid but different contexts:

```po
msgid "Active"
msgstr "Aktiv"

msgctxt "token status"
msgid "Active"
msgstr "Giltig"
```

The input format carries only a msgid, so `translate` resolves it as follows:

- If exactly one entry has that msgid, it is updated.
- If several do, the **contextless** entry is updated and the context-carrying
  ones are left alone.
- If the msgid exists *only* under two or more different contexts, it cannot be
  resolved. The command reports it and writes nothing; with `--force` it is
  skipped and listed under "Ambiguous".

To target a context-carrying entry directly, use the programmatic API with a
`{msgctxt, msgid}` key:

```elixir
GettextOps.Writer.update_translations(path, %{{"token status", "Active"} => "Giltig"})
```

**Examples:**

```bash
# From file
mix gettext_ops.translate --locale sv translations.txt

# From stdin (heredoc)
mix gettext_ops.translate --locale sv <<EOF
Sign In = Logga in
Sign Out = Logga ut
EOF

# From pipe
echo "Welcome = Välkommen" | mix gettext_ops.translate --locale sv

# With file flag (explicit)
mix gettext_ops.translate --locale sv --file translations.txt
```

**Input file format (`translations.txt`):**
```
Sign In = Logga in
Sign Out = Logga ut
Welcome = Välkommen
Error: Invalid input = Fel: Ogiltig inmatning
```

---

### `mix gettext_ops.change_msgid`

Update a **msgid** (source text) across all locale files, .pot templates, and source code references. This changes the source text everywhere while preserving existing translations.

**Arguments:**
- `old_msgid` - Current msgid to replace
- `new_msgid` - New msgid text

**Options:**
- `--dry-run` - Preview changes without modifying files
- `--domain` / `-d` - Gettext domain (default: `default`)

**Examples:**

```bash
# Update msgid everywhere
mix gettext_ops.change_msgid "Sign In" "Log In"

# Preview changes first
mix gettext_ops.change_msgid --dry-run "Sign In" "Log In"
```

**What it does:**
1. Finds all `.po` files in `priv/gettext/*/LC_MESSAGES/`
2. Finds `.pot` template files
3. Updates the msgid in all matching entries across all locales, including
   context-carrying ones — a typo in the source text is a typo in each of its
   contexts
4. Preserves all translations (msgstr values remain intact)
5. Updates source code references if applicable
6. Shows summary of changes

**Example output:**
```
✓ priv/gettext/sv/LC_MESSAGES/default.po (1 entry)
✓ priv/gettext/en/LC_MESSAGES/default.po (1 entry)
✓ priv/gettext/default.pot (1 entry)

Updated 3 file(s) with 3 total entries
```

---

## Configuration

By default, gettext_ops looks for translations in:
```
priv/gettext/{locale}/LC_MESSAGES/{domain}.po
```

This matches Phoenix's default Gettext structure.

### Custom Configuration

If your project uses a different structure, configure in `config/config.exs`:

```elixir
config :gettext_ops,
  gettext_path: "translations",  # Custom base path
  default_domain: "messages"     # Custom default domain
```

## AI Agent Configuration

Add this prompt to your `CLAUDE.md`, `.github/agents.md`, or AI agent configuration to help agents work efficiently with translations:

```markdown
# Working with Gettext Translations

This project uses **gettext_ops** for managing translations. NEVER read `.po` files directly - they are large (1000+ lines) and waste tokens.

## Available Commands

### List untranslated entries
```bash
# See what needs translation
mix gettext_ops.list_untranslated --locale LOCALE --json --limit 10
```

### Search translations
```bash
# Search by msgid (source text)
mix gettext_ops.search "pattern" --locale LOCALE --json

# Search by msgstr (translated text)
mix gettext_ops.search_value "pattern" --locale LOCALE --json
```

### Apply translations
```bash
# Update translations (format: msgid = msgstr)
mix gettext_ops.translate --locale LOCALE <<EOF
English text = Translated text
Another string = Another translation
EOF
```

### Change source text globally
```bash
# Updates msgid in all .po files, .pot templates, and source code
mix gettext_ops.change_msgid "Old Text" "New Text"
```

## Workflow

1. **Finding work**: Use `list_untranslated` to see what needs translation
2. **Searching**: Use `search` (msgid) or `search_value` (msgstr) to find specific entries
3. **Translating**: Get strings with `list_untranslated --json`, translate them, then apply with `translate`
4. **Changing copy**: Use `change_msgid` to update source text everywhere

## Key Points

- Always use `--json` flag for structured output
- Translation format is: `msgid = msgstr` (one per line)
- `translate` updates msgstr (translations)
- `change_msgid` updates msgid (source text) across all files
- Never edit `.po` files manually
```

## LLM Integration Workflow

### Example: Translate with Claude/GPT

```bash
# 1. Get untranslated entries as JSON
mix gettext_ops.list_untranslated --locale sv --json --limit 20 > to_translate.json

# 2. Send to LLM (via API or copy-paste)
cat to_translate.json | llm "Translate these English strings to Swedish. \
Output format: 'English = Swedish' (one per line)"

# 3. Save LLM output to file
# (LLM outputs: Sign In = Logga in, etc.)

# 4. Apply translations
mix gettext_ops.translate --locale sv translations.txt
```

### Example: Change copy with AI assistance

```bash
# Find the current text
mix gettext_ops.search "Sign In" --json

# Ask LLM for better alternative
# LLM suggests: "Log In" is more standard

# Update msgid everywhere (all .po files, .pot templates, and source code)
mix gettext_ops.change_msgid "Sign In" "Log In"
```

## How It Works

### Built on Expo

gettext_ops uses the [Expo](https://hex.pm/packages/expo) library for .po file parsing and writing. Expo is the same library used by Phoenix's Gettext module, ensuring compatibility and reliability.

### Streaming Operations

Commands like `list_untranslated` and `search` stream through .po files entry-by-entry, extracting only matching entries. This means:

- **Low memory usage** - Don't load entire files into memory
- **Fast results** - Return results as soon as they're found
- **Token efficient** - Only output what's needed

### File Updates

Commands like `translate` and `change_msgid`:

1. Parse the original .po file using Expo
2. Update matching entries
3. Write back using Expo's composer
4. Preserve all formatting, comments, and metadata

## Comparison with Existing Tools

| Tool | Purpose | Relation to gettext_ops |
|------|---------|------------------------|
| **`mix gettext.extract`** | Extract translatable strings from source code | Complementary - run before using gettext_ops |
| **`mix gettext.merge`** | Merge extracted strings into .po files | Complementary - creates files that gettext_ops works with |
| **`gettext_llm`** | Bulk translate entire .po files via LLM APIs | Different - automated translation vs. targeted operations |
| **`gettext_check`** | Check for missing translations | Similar goal, but gettext_ops provides actionable output |
| **Expo** | Low-level .po parser/writer library | Foundation - gettext_ops builds on Expo |

**gettext_ops fills a gap:** It provides targeted, scriptable operations for working with individual translation entries, designed for both human and AI workflows.

## Troubleshooting

### "No .po file found"

Check that your locale directory exists:
```bash
ls priv/gettext/sv/LC_MESSAGES/default.po
```

Run `mix gettext.extract --merge` to create initial files.

### "msgid not found" when translating

The msgid in your translation file must exactly match the msgid in the .po file. Use `--force` to see warnings:

```bash
mix gettext_ops.translate --locale sv --force translations.txt
```

Check for:
- Extra whitespace
- Different quotes
- Typos

### "ambiguous msgid" when translating

The msgid exists in the .po file only under two or more different `msgctxt`
values, so a bare msgid cannot say which entry you mean. The command lists the
contexts it found. Use the programmatic API with a `{msgctxt, msgid}` key to
target one, or `--force` to skip it.

### "refusing to write: would produce duplicate entries"

The operation would have produced a .po file holding two entries with the same
`{msgctxt, msgid}` pair — a file gettext and `Expo.PO.parse_file!/1` cannot
read. The file is left untouched. This usually means a `change_msgid` rename
collided with a msgid the file already uses.

### JSON output is malformed

Each command outputs line-delimited JSON (one JSON object per line):

```bash
# ✅ Correct - one object per line
{"msgid":"A","msgstr":""}
{"msgid":"B","msgstr":""}

# ❌ Incorrect - not a JSON array
[{"msgid":"A"},{"msgid":"B"}]
```

This format is designed for streaming and piping. To parse as JSON array:

```bash
mix gettext_ops.list_untranslated --locale sv --json | jq -s '.'
```

## Roadmap

Future features under consideration:

- [ ] Support for `msgid_plural` / `msgstr[n]` (plural forms)
- [ ] Support for `msgctxt` (message context)
- [ ] Fuzzy matching for approximate searches
- [ ] Batch edit multiple msgids at once
- [ ] Translation coverage statistics
- [ ] Interactive mode for human translators
- [ ] Integration with translation services (DeepL, Google Translate)

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Links

- [Hex Package](https://hex.pm/packages/gettext_ops)
- [GitHub Repository](https://github.com/xnilsson/gettext_ops)
- [Issue Tracker](https://github.com/xnilsson/gettext_ops/issues)
- [Expo Library](https://hex.pm/packages/expo)
- [Phoenix Gettext Guide](https://hexdocs.pm/phoenix/gettext.html)

---

**gettext_ops** - Targeted Mix tasks for Phoenix Gettext translations
