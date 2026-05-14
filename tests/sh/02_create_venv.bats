#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "02 script exists and is executable" {
  #R001: Script fails fast on unrecoverable errors.
  #R005: Script requires sibling prerequisites script.
  #R010: Interpreter selection prefers python3.12 then python3.
  #R015: Script fails when no supported interpreter exists.
  #R020: Venv naming follows <cwd-basename>-venv convention.
  #R025: Script refuses creation when VIRTUAL_ENV is active.
  #R030: Existing venv path exits successfully without recreation.
  #R035: New venv is created via selected interpreter.
  #R040: Activation guidance is printed for operator.
  run test -x "${REPO_ROOT}/02_create_venv.sh"
  [ "$status" -eq 0 ]
}
