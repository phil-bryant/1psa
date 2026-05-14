# cmd/1psa main Requirements

## Scope

Applies to `cmd/1psa/main.go`.

R001 Statement: Parse CLI flags and enforce single-command invocation.
Design: Accept exactly one command mode (`-l`, `-f`, `-m`, `-u`, `-p`) and print usage on invalid combinations.
Tests:
- Verify no-flag invocation prints usage.
- Verify multi-flag invocation prints a validation error and usage.

R005 Statement: Initialize 1Password client before command execution.
Design: Call `onepsa.CreateClient()` and fail command execution with clear fatal error when client creation fails.
Tests:
- Verify command exits with a fatal error when client initialization fails.

R010 Statement: Route each CLI mode to matching text output helpers.
Design: Dispatch list/field/multi-field/username/password modes to onepsa helper functions and print output with stable newline behavior.
Tests:
- Verify command-mode routing and output behavior for list and single-value paths.

## Changelog

- 2026-05-14: Added requirements coverage for `cmd/1psa/main.go`.
