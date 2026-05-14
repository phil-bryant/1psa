# python onepsa_ctypes Requirements

## Scope

Applies to `python/onepsa_ctypes.py`.

R001 Statement: Load shared library using repository-default path when not overridden.
Design: Resolve and open `bin/libonepsa.dylib` through `ctypes.CDLL` unless caller provides explicit path.
Tests:
- Verify constructor defaults to repository shared-library path.

R005 Statement: Define ctypes argument and return signatures for exported C functions.
Design: Configure argtypes/restype for `OnepsaStringFree`, list, field, and multi-field operations.
Tests:
- Verify wrapper initialization configures callable signatures for exported symbols.

R010 Statement: Convert C pointers into Python outputs with explicit error handling.
Design: Raise `OnepsaError` for error pointers and null outputs; decode and free successful output pointers.
Tests:
- Verify `_consume_result` error, null, and success behavior including free calls.

## Changelog

- 2026-05-14: Added requirements coverage for `python/onepsa_ctypes.py`.
