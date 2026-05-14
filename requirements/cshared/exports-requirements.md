# cshared exports Requirements

## Scope

Applies to `cshared/exports.go`.

R001 Statement: Expose C-callable wrappers for onepsa read operations.
Design: Export list/field/multi-field functions that return C strings and use a shared error-out pattern.
Tests:
- Verify exported wrapper package builds and peer tests compile.

R005 Statement: Validate required C inputs before invoking onepsa helpers.
Design: Return `nil` result with descriptive error when required item or field arguments are missing.
Tests:
- Verify nil-item and nil-field validation errors are surfaced by wrapper tests.

R010 Statement: Manage C string lifecycle safely for success and error paths.
Design: Allocate result/error strings with `C.CString` and expose `OnepsaStringFree` to release allocated memory.
Tests:
- Verify shared library smoke tests can free returned error/output strings.

## Changelog

- 2026-05-14: Added requirements coverage for `cshared/exports.go`.
