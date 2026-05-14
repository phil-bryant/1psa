#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "01 script exists and is executable" {
  #R001: Installer runs in strict bash mode.
  #R005: Homebrew is required for package operations.
  #R007: Homebrew paths are validated for writability.
  #R010: Homebrew formulas are installed when commands are missing.
  #R015: Python security tools are provisioned through pipx.
  #R017: Go security tools are provisioned through go install.
  #R018: govulncheck compatibility is rebuilt when required.
  #R020: Xcode privileged setup uses sudo authentication flow.
  #R030: Xcode first-launch setup is enforced and rechecked.
  #R050: Script emits phase-level status output.
  #R055: Reruns are idempotent when dependencies already exist.
  #R060: Script prints final readiness guidance.
  #R065: Optional SKIP_XCODE_SETUP flag bypasses Xcode setup.
  run test -x "${REPO_ROOT}/01_install_prerequisites.sh"
  [ "$status" -eq 0 ]
}
