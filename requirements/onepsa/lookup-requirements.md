# onepsa lookup Requirements

## Scope

Applies to `onepsa/lookup.go`.

R001 Statement: Enumerate accessible vaults before item lookup.
Design: List vaults from the SDK and fail with wrapped context when vault listing fails.
Tests:
- Verify vault-list failures return wrapped errors.

R005 Statement: Find items by case-insensitive title matching across vaults.
Design: Iterate vault item overviews and fetch full item details for first matching title.
Tests:
- Verify case-insensitive item-name lookups return expected item.

R010 Statement: Continue scanning when a vault item-list operation fails.
Design: Skip vaults that fail item listing and continue searching remaining vaults.
Tests:
- Verify lookup still succeeds when an earlier vault list call fails.

## Changelog

- 2026-05-14: Added requirements coverage for `onepsa/lookup.go`.
