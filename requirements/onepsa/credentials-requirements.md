# onepsa credentials Requirements

## Scope

Applies to `onepsa/credentials.go`.

R001 Statement: Validate item-name input for list-fields requests.
Design: Reject blank item names before vault/item lookups.
Tests:
- Verify blank item-name requests return a required-input error.

R005 Statement: Render deterministic list-all and list-item text output.
Design: Format vault/item listings with stable headings and field numbering.
Tests:
- Verify list-all and list-item output contains expected headings and entries.

R010 Statement: Continue rendering when per-vault item listing errors occur.
Design: Record vault item-listing errors inline and continue processing remaining vaults.
Tests:
- Verify list-all output includes inline vault error and still lists healthy vaults.

## Changelog

- 2026-05-14: Added requirements coverage for `onepsa/credentials.go`.
