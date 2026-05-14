#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "05 script exists and is executable" {
  #R001: Script runs in strict mode from repository root.
  #R005: Script autodiscovers Go unit tests and runs go test suite.
  #R010: Script autodiscovers Bats unit tests and runs bats suite.
  #R015: Script autodiscovers pytest tests and fails when pytest is unavailable.
  #R020: Script autodiscovers unittest tests and runs unittest discover.
  #R025: Script continues executing remaining suites after failures.
  #R030: Script prints final summary with checkmark/cross and returns matching exit code.
  run test -x "${REPO_ROOT}/05_run_unit_tests.sh"
  [ "$status" -eq 0 ]
}

@test "05 reports green checkmark when all discovered suites pass" {
  workdir="$(mktemp -d)"
  mockbin="${workdir}/mockbin"
  mkdir -p "${mockbin}" "${workdir}/pkg" "${workdir}/tests/sh" "${workdir}/tests/py" "${workdir}/python"
  cp "${REPO_ROOT}/05_run_unit_tests.sh" "${workdir}/05_run_unit_tests.sh"
  chmod +x "${workdir}/05_run_unit_tests.sh"

  touch "${workdir}/pkg/foo_test.go"
  touch "${workdir}/tests/sh/sample.bats"
  touch "${workdir}/tests/py/test_sample.py"
  touch "${workdir}/python/test_sample.py"

  cat > "${mockbin}/go" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat > "${mockbin}/bats" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat > "${mockbin}/python3" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-" ]]; then
  exit 0
fi
if [[ "${1:-}" == "-m" && "${2:-}" == "pytest" ]]; then
  exit 0
fi
if [[ "${1:-}" == "-m" && "${2:-}" == "unittest" ]]; then
  exit 0
fi
exit 0
EOF
  chmod +x "${mockbin}/go" "${mockbin}/bats" "${mockbin}/python3"

  run env PATH="${mockbin}:$PATH" bash "${workdir}/05_run_unit_tests.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Suites failed:     0"* ]]
  [[ "$output" == *"✅ All discovered unit test suites passed."* ]]
}

@test "05 reports red x and non-zero when any discovered suite fails" {
  workdir="$(mktemp -d)"
  mockbin="${workdir}/mockbin"
  mkdir -p "${mockbin}" "${workdir}/pkg" "${workdir}/tests/sh" "${workdir}/tests/py" "${workdir}/python"
  cp "${REPO_ROOT}/05_run_unit_tests.sh" "${workdir}/05_run_unit_tests.sh"
  chmod +x "${workdir}/05_run_unit_tests.sh"

  touch "${workdir}/pkg/foo_test.go"
  touch "${workdir}/tests/sh/sample.bats"
  touch "${workdir}/tests/py/test_sample.py"
  touch "${workdir}/python/test_sample.py"

  cat > "${mockbin}/go" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  cat > "${mockbin}/bats" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  cat > "${mockbin}/python3" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-" ]]; then
  exit 0
fi
if [[ "${1:-}" == "-m" && "${2:-}" == "pytest" ]]; then
  exit 0
fi
if [[ "${1:-}" == "-m" && "${2:-}" == "unittest" ]]; then
  exit 0
fi
exit 0
EOF
  chmod +x "${mockbin}/go" "${mockbin}/bats" "${mockbin}/python3"

  run env PATH="${mockbin}:$PATH" bash "${workdir}/05_run_unit_tests.sh"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Suites failed:     1"* ]]
  [[ "$output" == *"❌ One or more discovered unit test suites failed."* ]]
}
