# onepsa field Requirements

## Scope

Applies to `onepsa/field.go`.

R001 Statement: Return single-field values for matching item fields.
Design: Resolve item by name, perform case-insensitive field lookup, and return raw value.
Tests:
- Verify existing field requests return expected value.

R005 Statement: Normalize multi-field requests from comma/whitespace-separated input.
Design: Split and trim requested field tokens, dropping empty entries before lookup.
Tests:
- Verify normalized field list handling for mixed comma-separated input.

R010 Statement: Fail multi-field requests when any requested field is missing.
Design: Collect missing fields and return one descriptive error listing unresolved names.
Tests:
- Verify missing requested fields return deterministic error output.

## Changelog

- 2026-05-14: Added requirements coverage for `onepsa/field.go`.
