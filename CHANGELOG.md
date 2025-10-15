# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/xnilsson/gettext_ops/releases/tag/v0.1.0
