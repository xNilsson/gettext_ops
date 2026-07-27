# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-07-27

### Fixed

- **Catalogue corruption in `translate` (data loss).** Entries were keyed by
  msgid alone, but gettext identifies an entry by the pair `{msgctxt, msgid}`.
  Any two entries sharing a msgid collapsed onto whichever one won, so a
  contextless `msgid "Active"` was rewritten to carry `msgctxt "token status"`.
  The resulting file has two identical entries and `Expo.PO.parse_file!/1`
  refuses to read it, breaking compilation of the whole application.

  This fired on **every** write, including a single-string call, and on msgids
  that were never in the translation input — translating one unrelated string
  silently collapsed every duplicate-msgid pair in the catalogue.

- **Silent corruption in `change_msgid`.** Renaming a msgid onto one the file
  already used produced an unreadable catalogue and still reported `{:ok, ...}`.
  The rename is now refused and the file left untouched.

- **`Writer.update_translations/2` overwriting the wrong entries.** A bare msgid
  overwrote every entry sharing it, including context-carrying siblings that are
  distinct translations.

### Added

- `GettextOps.Entry.get_msgctxt/1` and `GettextOps.Entry.key/1`, exposing the
  `{msgctxt, msgid}` identity of an entry. `nil`, `[]` and `""` all normalise to
  "no context", matching Expo.
- `GettextOps.Writer.check_duplicates/1`, run before every write so a would-be
  corruption surfaces as a loud error instead of an unreadable .po file.
- `translate` reports an `:ambiguous` list for msgids that exist only under two
  or more different contexts, rather than silently picking one. Without
  `--force` this is an error; with `--force` they are skipped and listed.
- `msgctxt` is included in text and JSON output, so `search` and
  `list_untranslated` results distinguish entries that share a msgid.

### Changed

- `translate` resolves a bare msgid to the **contextless** entry when several
  entries share that msgid. Previously the choice was arbitrary.
- `Writer.update_translations/2` accepts `{msgctxt, msgid}` tuple keys to target
  a context-carrying entry. A bare msgid string now matches only the contextless
  entry — it no longer overwrites context-carrying siblings.

## [0.1.0] - 2025-10-15

### Added

- Initial release of gettext_ops
- `mix gettext_ops.list_untranslated` - List entries with empty translations
- `mix gettext_ops.search` - Search for entries by msgid (source text)
- `mix gettext_ops.search_value` - Search for entries by msgstr (translated text)
- `mix gettext_ops.translate` - Apply translations from stdin or file
- `mix gettext_ops.change_msgid` - Update msgid across all locale files
- Programmatic API for all operations via `GettextOps` module
- JSON output support for all commands (line-delimited JSON)
- LLM-friendly stdin/stdout patterns for AI agent workflows
- Token-efficient operations (targeted queries instead of reading entire files)
- Built on Expo library for reliable .po file parsing and writing
- Support for regex and substring search patterns
- Atomic file updates to prevent corruption
- Dry-run mode for `change_msgid` command
- Comprehensive documentation with examples
- Support for custom gettext paths and domains via configuration

### Features

- 🎯 Targeted queries - Get only the entries you need
- 📝 Bulk operations - Update multiple translations at once
- 🔄 Global edits - Change msgid across all language files
- 🤖 LLM-friendly - JSON output for easy parsing by AI tools
- ⚡ Fast - Streaming operations with low memory usage
- 🔧 Phoenix-native - Works with standard `priv/gettext` structure

[0.1.1]: https://github.com/xnilsson/gettext_ops/releases/tag/v0.1.1
[0.1.0]: https://github.com/xnilsson/gettext_ops/releases/tag/v0.1.0
