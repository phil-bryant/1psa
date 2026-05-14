# Install Prerequisites Requirements

## Scope

Applies to `01_install_prerequisites.sh` for local macOS setup used by this repository.
This installer is the source of truth for machine-level prerequisites used to build, test, and run `1psa` and related local tooling.

R001  Statement: Run with `bash` and fail fast on unrecoverable errors.
Design: Use `set -e` and return non-zero on any hard prerequisite failure.
Tests:
- Force a failing command and verify script exits non-zero.

R005  Statement: Require Homebrew before any package or cask operations.
Design: Verify `brew` exists on `PATH`; if missing, print install command and stop.
Tests:
- Run with `brew` absent and verify failure includes Homebrew install guidance.

R007 Statement: Fail early when Homebrew installation paths are not writable.
Design: Verify write access for key Homebrew paths (`brew --prefix`, `Cellar`, `bin`, and `~/Library/Logs/Homebrew`) before attempting installs.
Constraints:
- On permission failure, print concise ownership/permission remediation commands and exit non-zero.
Tests:
- Simulate non-writable Homebrew path and verify script exits before first install attempt.

R010  Statement: Provision Homebrew formula dependencies required by this project workflow.
Design: Ensure these commands are available, installing when absent: `go`, `git`, `bats` (`bats-core`), `clamscan` (`clamav`), `semgrep`, `gitleaks`, and `pipx`.
Constraints:
- Treat command availability on `PATH` as satisfied state.
- Validate command availability after each install; fail if still missing.
Tests:
- Run with each command missing and verify corresponding Homebrew install is attempted.
- Run with all commands present and verify formula installs are skipped.

R015  Statement: Provision Python security CLIs required by `04_run_security_checks.sh`.
Design: Ensure `bandit`, `pip-audit`, and `detect-secrets` are available using `pipx` installs when commands are missing.
Constraints:
- Treat command availability on `PATH` as satisfied state.
- During script runtime, prepend `~/.local/bin` to `PATH` so freshly installed pipx commands are immediately discoverable.
- After install, accept either direct `PATH` availability or executable presence under `~/.local/bin`.
Tests:
- Run with each command missing and verify `pipx install --include-deps` is attempted.
- Run with all commands present and verify pipx installs are skipped.
- Run in a shell without `~/.local/bin` on PATH and verify script still validates installed pipx commands.

R017  Statement: Provision Go security CLIs required by `04_run_security_checks.sh`.
Design: Ensure `gosec` and `govulncheck` are available; when missing, install via `go install <module>@latest`.
Constraints:
- Treat command availability on `PATH` as satisfied state.
- After install, accept either direct `PATH` availability or executable presence under `$(go env GOPATH)/bin`.
Tests:
- Run with each command missing and verify `go install` is attempted.
- Verify post-install checks pass when binaries land in `GOPATH/bin`.

R018 Statement: Keep `govulncheck` aligned with the currently active Go toolchain.
Design: Run a compatibility probe for `govulncheck` against repo packages; if Go-version/package-pattern mismatch diagnostics are detected, rebuild `govulncheck` via `go install ...@latest` and re-verify.
Constraints:
- Treat unresolved post-rebuild mismatch diagnostics as a hard failure in the prerequisites phase.
Tests:
- Simulate a stale `govulncheck` binary built with an older Go version and verify the script rebuilds it automatically.
- Verify the script exits non-zero when mismatch diagnostics remain after rebuild.

R020  Statement: Use standard `sudo` authentication for privileged Xcode initialization.
Design: For Xcode first-launch and license acceptance commands, run privileged operations via `sudo` and allow interactive authentication.
Constraints:
- Re-prompt credential checks with `sudo -k` before each privileged command.
- Do not embed hardcoded credentials in script or requirements.
Tests:
- Verify installer runs privileged Xcode operations through `sudo xcodebuild ...`.

R030  Statement: Ensure Xcode command-line prerequisites are configured for local builds.
Design: Require `xcodebuild`; if first-launch setup is incomplete, run `xcodebuild -runFirstLaunch` and accept license when needed.
Constraints:
- Fail with guidance (`xcode-select --install`) when `xcodebuild` is unavailable.
- Re-check first-launch status and fail if still incomplete after setup.
Tests:
- Run on machine without first-launch complete and verify initialization path executes.
- Run on machine already configured and verify Xcode phase exits without reconfiguration.

R050  Statement: Emit explicit status output for each major prerequisite phase.
Design: Print phase-level check/install/success/failure lines for Homebrew, brew formulas, pipx tools, Go tools, and Xcode phases.
Tests:
- Run installer and verify each major phase emits clear status lines.

R055  Statement: Keep installer idempotent across reruns.
Design: Skip clone/install/build actions when existing dependencies and repositories already satisfy checks.
Tests:
- Run installer twice and verify second run performs no unnecessary install/clone operations.

R060  Statement: Print final local readiness guidance after successful completion.
Design: End with success banner and current local repository path.
Tests:
- Verify successful run output includes success banner and repository path reference.

R065 Statement: Support optional skip of Xcode privileged setup for non-interactive runs.
Design: Honor `SKIP_XCODE_SETUP=true` to bypass Xcode first-launch/license checks while still running all non-Xcode prerequisite phases.
Tests:
- Run with `SKIP_XCODE_SETUP=true` and verify script skips Xcode phase cleanly.

## Changelog

- 2026-04-28: Added Homebrew writable-path preflight checks to fail fast with explicit ownership remediation commands.
- 2026-04-28: Added pipx PATH handling (`~/.local/bin`) so security CLIs are discoverable immediately after installation.
- 2026-05-14: Added `gitleaks` Homebrew prerequisite for secret scanning coverage in `04_run_security_checks.sh`.
- 2026-05-14: Added automatic `govulncheck` rebuild/recheck logic to keep it compatible with the active Go toolchain.
- 2026-04-28: Added security-tool prerequisites (`semgrep`, `pipx`, `bandit`, `pip-audit`, `detect-secrets`, `gosec`, `govulncheck`) to unblock `04_run_security_checks.sh`.
- 2026-04-28: Added optional `SKIP_XCODE_SETUP=true` behavior for non-interactive prerequisite runs.
- 2026-04-28: Rewrote requirements to align with actual `01_install_prerequisites.sh` behavior and repository prerequisites.
- 2026-04-28: Removed non-repo prerequisites: `swiftlint`, `perl`, `cpanminus`, `pg_install`, and pgTAP install flows.
- 2026-04-28: Removed circular `1psa` bootstrap requirement; switched privileged Xcode steps to standard `sudo` authentication.
