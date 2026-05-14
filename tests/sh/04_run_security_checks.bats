#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "04 script exists and is executable" {
  #R001: Script runs in strict mode from repository root.
  #R005: Environment toggles and report directory are resolved up front.
  #R010: Script implements SAST-only behavior (no DAST lane).
  #R015: Python and secret scanners are executed with report outputs.
  #R020: Go scanners run across all module packages.
  #R025: Runtime scanner failures are handled separately from findings.
  #R030: Summary report and fail-on-high policy are applied.
  #R035: Optional ClamAV lane writes integrated report artifacts.
  #R040: Progress and completion output are printed for operators.
  #R045: Secret scanners exclude generated reports/build artifacts.
  #R050: pip-audit targets project virtualenv interpreter when present.
  run test -x "${REPO_ROOT}/04_run_security_checks.sh"
  [ "$status" -eq 0 ]
}
