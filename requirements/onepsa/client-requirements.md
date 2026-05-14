# onepsa client Requirements

## Scope

Applies to `onepsa/client.go`.

R001 Statement: Resolve default service-account token location from user home directory.
Design: Build the default token path as `~/.1psa` before client initialization.
Tests:
- Verify client creation reports useful errors when token file is missing.

R005 Statement: Read token bytes and normalize whitespace before SDK initialization.
Design: Load token file contents and trim whitespace before passing token to the SDK client constructor.
Tests:
- Verify whitespace-only token content still reaches client creation path with normalized value.

R010 Statement: Return wrapped errors for home-dir, token-read, and SDK-client failures.
Design: Include operation context in returned errors to improve diagnostics.
Tests:
- Verify error messages include read-token and create-client context.

## Changelog

- 2026-05-14: Added requirements coverage for `onepsa/client.go`.
