#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "03 script exists and remains locked from AI edits" {
  #R001: Script requires expected project virtual environment directory.
  #R005: Script requires an active virtual environment.
  #R010: Active venv must match expected project venv path.
  #R015: Requirements source is selected by deterministic precedence.
  #R020: CPU/GPU selector is validated for split requirements mode.
  #R025: Dependency install flow upgrades pip then installs requirements.
  #R030: Locked-file traceability exception policy remains in effect.
  run rg -n "DO_NOT_MODIFY_THIS_FILE" "${REPO_ROOT}/03_load_requirements.sh"
  [ "$status" -eq 0 ]
}
