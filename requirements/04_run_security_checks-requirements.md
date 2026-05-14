# Run Security Checks Requirements

## Scope

Applies to `04_run_security_checks.sh`.

R001 Statement: Run in strict shell mode from repository root.
Design: Use `set -euo pipefail`, resolve script directory from `${BASH_SOURCE[0]}`, and `cd` into that directory.
Tests:
- Run the script from a different working directory and verify reports are still written under repo-local `.security-reports`.

R005 Statement: Support explicit SAST lane toggling and report destination.
Design: Resolve `RUN_SAST`, `RUN_CLAMAV`, `SECURITY_REPORT_DIR`, and `SECURITY_FAIL_ON_HIGH_CRITICAL` from environment and create report dir before scans.
Tests:
- Run with `RUN_SAST=false` and verify clean early exit.
- Run with custom `SECURITY_REPORT_DIR` and verify all artifacts are written there.

R010 Statement: Exclude DAST entirely from this repository's security checks.
Design: The script must not start HTTP targets, OpenAPI fuzzing, ZAP scans, token-capture flows, or UI DAST; no DAST toggles or DAST artifacts are allowed.
Tests:
- Search script output and report directory to verify only SAST tool outputs are produced.

R015 Statement: Run Python and secret-focused SAST checks against repo-local source.
Design: Execute Semgrep, Bandit (`./python`), pip-audit, detect-secrets, and gitleaks; write JSON artifacts under report dir.
Tests:
- Verify `semgrep.json`, `bandit.json`, `pip-audit.json`, `detect-secrets.json`, and `gitleaks.json` exist after a SAST run.

R020 Statement: Run Go SAST checks across all module packages.
Design: Execute `gosec`, `govulncheck`, and `go vet` for `./...`; persist outputs as `gosec.json`, `govulncheck.json`, and `go-vet.txt`.
Constraints:
- Treat `govulncheck` package-loading and Go-version compatibility errors as hard failures (for example package pattern parsing errors or "file requires newer Go version" diagnostics).
Tests:
- Verify the three Go artifacts exist after a SAST run.
- Simulate a `govulncheck` Go-version mismatch and verify the script exits non-zero with an explicit failure message.

R025 Statement: Keep scanner execution failures distinct from findings.
Design: Treat allowed findings exits as non-fatal where tool semantics require (`1`), but fail on true execution errors.
Tests:
- Stub or simulate a scanner runtime failure and verify script exits non-zero with a failure message.

R030 Statement: Produce consolidated SAST summary and apply blocking policy.
Design: Aggregate high/critical counts from scanner artifacts into `sast-summary.json`; exit non-zero when `SECURITY_FAIL_ON_HIGH_CRITICAL=true` and totals are non-zero.
Tests:
- Seed one high-severity finding and verify gate failure when fail-on-high is enabled.
- Re-run with `SECURITY_FAIL_ON_HIGH_CRITICAL=false` and verify script completes.

R035 Statement: Support optional ClamAV malware scan with report integration.
Design: When `RUN_CLAMAV=true`, run `clamscan`, write `clamav.log` and `clamav-summary.json`, and include infected file counts in `sast-summary.json`.
Constraints:
- If ClamAV is unavailable or returns runtime setup errors (for example missing local signature database), do not fail the entire SAST run; record the failure reason in `clamav-summary.json` and continue.
Tests:
- Run with `RUN_CLAMAV=false` and verify skipped summary payload is still emitted.
- Run with `RUN_CLAMAV=true` and verify ClamAV artifacts are produced.
- Simulate missing ClamAV setup and verify script continues while persisting a non-empty `error` field in `clamav-summary.json`.

R040 Statement: Emit operator-readable progress and completion output.
Design: Print per-tool headers, lane progress, and final report directory path.
Tests:
- Verify run output clearly indicates start, per-tool execution, and completion path.

R045 Statement: Secret scanners must avoid recursive findings from generated scan artifacts.
Design: Configure secret-scanning tools (at minimum `gitleaks`, `detect-secrets`) to exclude generated security outputs and non-source build artifacts (at minimum `.security-reports/` and `bin/`) so scanner outputs are not re-scanned as candidate secrets.
Tests:
- Seed synthetic token-like strings inside `.security-reports/` and verify secret scanners do not report those paths.
- Verify gitleaks output paths are limited to source-scope files and exclude `.security-reports/*`.

R050 Statement: Preserve Python supply-chain coverage for the project virtual environment.
Design: Resolve the project venv interpreter (`PROJECT_VENV_DIR`) and run `pip-audit` against that interpreter when present; this dependency-vulnerability lane remains enabled even when secret scanners exclude generated/runtime directories.
Tests:
- Run with default `PROJECT_VENV_DIR` and verify output reports `pip-audit target interpreter: ./1psa-venv/bin/python3` (or equivalent project-venv path).
- Run with a custom `PROJECT_VENV_DIR` and verify `pip-audit` targets that interpreter.

## How To Triage Secret Findings

1. Classify by file type first: source file, generated artifact, dependency/runtime directory, or report output.
2. Validate rule context before remediating (for example, `sourcegraph-access-token` may misclassify long SHA-like substrings in advisory/reference URLs).
3. Choose the remediation type:
   - Real secret in source/history: rotate credential and remove from code/history per incident procedure.
   - False positive in generated artifact: tune scanner scope/exclusions; do not suppress real-source findings broadly.
   - Ambiguous finding: isolate and re-run the single scanner against the file/path in question.
4. Re-run targeted scans, then full `04_run_security_checks.sh`, and confirm gate behavior matches expected risk.

## Changelog

- 2026-05-14: Added explicit secret-scanner anti-recursion scope requirement and project-venv supply-chain coverage requirement; documented triage workflow for false-positive classification.
- 2026-05-14: Captured gitleaks false-positive incident where `.security-reports/govulncheck.json` advisory-reference SHA-like substrings were flagged as `sourcegraph-access-token`.
- 2026-05-14: Made `govulncheck` Go-version/package-pattern mismatch diagnostics a hard failure condition.
- 2026-05-14: Added `gitleaks` scanning coverage and ClamAV graceful-degradation requirement for missing runtime setup.
- 2026-04-28: Replaced teller-derived mixed SAST/DAST requirements with 1psa-specific SAST-only requirements and Go-inclusive coverage.
