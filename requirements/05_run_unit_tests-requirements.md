# Run Unit Tests Requirements

## Scope

Applies to `05_run_unit_tests.sh`.

R001 Statement: Run in strict shell mode from repository root.
Design: Use `set -euo pipefail`, resolve the script directory from `${BASH_SOURCE[0]}`, and `cd` to that directory before discovery.
Tests:
- Run from a different working directory and verify discovery still targets repository-local paths.

R005 Statement: Autodiscover Go unit tests and run them as a single suite.
Design: Detect the presence of `*_test.go` files and run `go test ./...` when any are found.
Tests:
- Create a temporary Go test file and verify the Go suite is executed.

R010 Statement: Autodiscover Bats unit tests and run them as a suite.
Design: Detect `tests/sh/*.bats` and execute `bats` against discovered files.
Tests:
- Add temporary `.bats` files and verify the Bats suite is executed.

R015 Statement: Autodiscover pytest-style Python unit tests.
Design: Detect `tests/py/test_*.py` and run `python3 -m pytest` on discovered files.
Constraints:
- If pytest-style files are discovered but `pytest` is unavailable, treat it as a suite failure.
Tests:
- Verify script fails with clear message when pytest tests exist but `pytest` is unavailable.

R020 Statement: Autodiscover unittest-style Python unit tests.
Design: Detect `python/test_*.py` and run `python3 -m unittest discover -s python -p 'test_*.py'`.
Tests:
- Add temporary unittest module under `python/` and verify unittest discovery executes.

R025 Statement: Keep suite execution isolated and continue through failures.
Design: Execute each discovered suite independently, record pass/fail outcome per suite, and continue running remaining suites.
Tests:
- Force one suite to fail and verify later suites still execute.

R030 Statement: Emit quick final summary with pass/fail status icon.
Design: Print suite counts and finish with `✅` when all discovered suites pass or `❌` when any suite fails; return non-zero on failures.
Tests:
- Verify successful run prints green checkmark summary.
- Verify failing run prints red X summary and exits non-zero.

## Changelog

- 2026-05-14: Initial requirements for `05_run_unit_tests.sh` autodiscovery and summary behavior.
