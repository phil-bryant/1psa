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

R015 Statement: Run Python SAST and dependency checks against repo-local Python surface.
Design: Execute Semgrep, Bandit (`./python`), pip-audit, and detect-secrets; write JSON artifacts under report dir.
Tests:
- Verify `semgrep.json`, `bandit.json`, `pip-audit.json`, and `detect-secrets.json` exist after a SAST run.

R020 Statement: Run Go SAST checks across all module packages.
Design: Execute `gosec`, `govulncheck`, and `go vet` for `./...`; persist outputs as `gosec.json`, `govulncheck.json`, and `go-vet.txt`.
Tests:
- Verify the three Go artifacts exist after a SAST run.

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
Tests:
- Run with `RUN_CLAMAV=false` and verify skipped summary payload is still emitted.
- Run with `RUN_CLAMAV=true` and verify ClamAV artifacts are produced.

R040 Statement: Emit operator-readable progress and completion output.
Design: Print per-tool headers, lane progress, and final report directory path.
Tests:
- Verify run output clearly indicates start, per-tool execution, and completion path.

## Changelog

- 2026-04-28: Replaced teller-derived mixed SAST/DAST requirements with 1psa-specific SAST-only requirements and Go-inclusive coverage.
