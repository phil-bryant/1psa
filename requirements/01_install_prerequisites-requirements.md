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

R010  Statement: Provision Homebrew formula dependencies required by this project workflow.
Design: Ensure these commands are available, installing when absent: `go`, `git`, `bats` (`bats-core`), and `clamscan` (`clamav`).
Constraints:
- Treat command availability on `PATH` as satisfied state.
- Validate command availability after each install; fail if still missing.
Tests:
- Run with each command missing and verify corresponding Homebrew install is attempted.
- Run with all commands present and verify formula installs are skipped.

R015  Statement: Ensure OWASP ZAP CLI wrapper is present for local security tooling.
Design: Check configured ZAP wrapper path (default `/Applications/ZAP.app/Contents/MacOS/ZAP.sh`); install Homebrew cask `zap` when missing.
Constraints:
- Support `ZAP_APP_PATH`/`ZAP_CLI_PATH` environment overrides.
- Fail with clear guidance if wrapper is still absent after install.
Tests:
- Run without ZAP and verify `brew install --cask zap` is executed.
- Simulate missing wrapper after cask install and verify explicit failure message.

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
Design: Print phase-level check/install/success/failure lines for Homebrew, tool formulas, ZAP, and Xcode phases.
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

## Changelog

- 2026-04-28: Rewrote requirements to align with actual `01_install_prerequisites.sh` behavior and repository prerequisites.
- 2026-04-28: Removed non-repo prerequisites: `swiftlint`, `perl`, `cpanminus`, `pg_install`, and pgTAP install flows.
- 2026-04-28: Removed circular `1psa` bootstrap requirement; switched privileged Xcode steps to standard `sudo` authentication.
