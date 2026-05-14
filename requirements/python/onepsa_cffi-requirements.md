# python onepsa_cffi Requirements

## Scope

Applies to `python/onepsa_cffi.py`.

R001 Statement: Load shared library using repository-default path when not overridden.
Design: Resolve `bin/libonepsa.dylib` from repository layout when `lib_path` is omitted.
Tests:
- Verify constructor defaults to repository shared-library path.

R005 Statement: Wrap C exported functions with typed cffi signatures.
Design: Define `OnepsaListAll`, `OnepsaListFields`, `OnepsaGetField`, and `OnepsaGetMulti` signatures before loading the library.
Tests:
- Verify wrappers can call exported functions in smoke tests.

R010 Statement: Convert C result/error pointers into Python exceptions or strings.
Design: Raise `OnepsaError` for explicit error pointers or null-without-error responses; free C strings after conversion.
Tests:
- Verify `_consume_result` handles error, null, and success paths with expected freeing behavior.

## Changelog

- 2026-05-14: Added requirements coverage for `python/onepsa_cffi.py`.
