#!/usr/bin/env bash
umask 007
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if [[ -d "$(go env GOPATH)/bin" ]]; then PATH="$(go env GOPATH)/bin:${PATH}"; fi
if [[ -d "$HOME/.local/bin" ]]; then PATH="$HOME/.local/bin:${PATH}"; fi

REPORT_DIR="${SECURITY_REPORT_DIR:-./.security-reports}"
RUN_SAST="${RUN_SAST:-true}"
RUN_CLAMAV="${RUN_CLAMAV:-true}"
FAIL_ON_HIGH_CRITICAL="${SECURITY_FAIL_ON_HIGH_CRITICAL:-true}"
PROJECT_VENV_DIR="${PROJECT_VENV_DIR:-./$(basename "$SCRIPT_DIR")-venv}"
mkdir -p "$REPORT_DIR"

print_tool_header() {
  local tool_name="$1" line_1="$2" line_2="$3" tool_url="$4"
  local border="+==============================================================================+"
  printf '%s\n' "$border"
  printf '| %-76s |\n' "Security Tool: ${tool_name}"
  printf '| %-76s |\n' "$line_1"
  printf '| %-76s |\n' "$line_2"
  printf '| %-76s |\n' "URL: ${tool_url}"
  printf '%s\n' "$border"
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then return 0; fi
  echo "Missing required command: $1"
  echo "Install prerequisites and repo dependencies, then retry."
  exit 1
}

run_semgrep() {
  print_tool_header "Semgrep" "Repo-level static analysis for insecure patterns." "Uses curated Python and Go rulesets." \
    "https://semgrep.dev/"
  set +e
  semgrep --config p/security-audit --config p/python --config p/golang --exclude ".security-reports/**" --json \
    --output "${REPORT_DIR}/semgrep.json" .
  local code=$?
  set -e
  if [[ "$code" -ne 0 && "$code" -ne 1 ]]; then echo "Semgrep execution failed."; exit 1; fi
}

run_bandit() {
  print_tool_header "Bandit" "Python-focused static checks for risky code paths." "Targets this repo's ./python directory only." \
    "https://bandit.readthedocs.io/"
  if [[ ! -d "./python" ]]; then
    printf '{"results":[]}\n' > "${REPORT_DIR}/bandit.json"
    echo "bandit findings: 0 (report: ${REPORT_DIR}/bandit.json)"
    return 0
  fi
  set +e
  bandit -q -r ./python -f json -o "${REPORT_DIR}/bandit.json"
  local code=$?
  set -e
  if (( code > 1 )); then echo "Bandit execution failed."; exit 1; fi
  python3 - <<'PY' "${REPORT_DIR}/bandit.json"
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"results": []}
results = payload.get("results", []) if isinstance(payload, dict) else []
print(f"bandit findings: {len(results)} (report: {path})")
for item in results[:5]:
    print(f"  - {item.get('filename', '?')}:{item.get('line_number', '?')} [{item.get('issue_severity', '?')}] {item.get('test_id', '')}")
if len(results) > 5: print(f"  ... and {len(results) - 5} more")
PY
}

configure_pip_audit_python() {
  local project_python=""
  if [[ -x "${PROJECT_VENV_DIR}/bin/python3" ]]; then
    project_python="${PROJECT_VENV_DIR}/bin/python3"
  elif [[ -x "${PROJECT_VENV_DIR}/bin/python" ]]; then
    project_python="${PROJECT_VENV_DIR}/bin/python"
  fi
  if [[ -n "$project_python" ]]; then
    export PIPAPI_PYTHON_LOCATION="$project_python"
    echo "pip-audit target interpreter: ${PIPAPI_PYTHON_LOCATION}"
  else
    unset PIPAPI_PYTHON_LOCATION || true
    echo "pip-audit target interpreter: default environment"
  fi
}

run_pip_audit() {
  print_tool_header "pip-audit" "Dependency vulnerability scan for Python packages." \
    "Audits dependencies from this repo's Python environment." "https://github.com/pypa/pip-audit"
  configure_pip_audit_python
  set +e
  pip-audit --format json --output "${REPORT_DIR}/pip-audit.json"
  local code=$?
  set -e
  if (( code > 1 )); then echo "pip-audit execution failed."; exit 1; fi
}

run_detect_secrets() {
  print_tool_header "detect-secrets" "Secret detection across tracked repository files." \
    "Flags likely credentials and high-entropy strings." "https://github.com/Yelp/detect-secrets"
  detect-secrets scan --all-files --force-use-all-plugins --exclude-files '(^\.git/|^\.security-reports/|^\.security-venv/|^bin/|.+-venv/)' \
    > "${REPORT_DIR}/detect-secrets.json"
  python3 - <<'PY' "${REPORT_DIR}/detect-secrets.json"
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"results": {}}
results = payload.get("results", {}) if isinstance(payload, dict) else {}
findings = sum(len(v) for v in results.values()) if isinstance(results, dict) else 0
print(f"detect-secrets findings: {findings} (report: {path})")
if findings > 0:
    printed = 0
    for file_name, entries in results.items():
        for entry in entries:
            print(f"  - {file_name}:{entry.get('line_number', '?')} [{entry.get('type', 'unknown')}]")
            printed += 1
            if printed >= 5:
                if findings > printed: print(f"  ... and {findings - printed} more")
                raise SystemExit(0)
PY
}

run_gosec() {
  print_tool_header "gosec" "Go static analysis for security anti-patterns." \
    "Scans all Go packages in the workspace." "https://github.com/securego/gosec"
  set +e
  gosec -fmt=json -out "${REPORT_DIR}/gosec.json" ./...
  local code=$?
  set -e
  if [[ "$code" -ne 0 && "$code" -ne 1 ]]; then echo "gosec execution failed."; exit 1; fi
}

run_govulncheck() {
  print_tool_header "govulncheck" "Go dependency and call-path vulnerability analysis." \
    "Finds known CVEs reachable from module code." "https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck"
  set +e
  govulncheck -json ./... > "${REPORT_DIR}/govulncheck.json"
  local code=$?
  set -e
  if [[ "$code" -ne 0 && "$code" -ne 1 ]]; then echo "govulncheck execution failed."; exit 1; fi
  python3 - <<'PY' "${REPORT_DIR}/govulncheck.json"
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
findings = 0
if path.exists():
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line: continue
        try:
            if json.loads(line).get("finding"): findings += 1
        except Exception:
            continue
print(f"govulncheck findings: {findings} (report: {path})")
PY
}

run_go_vet() {
  print_tool_header "go vet" "Go analyzer for suspicious code constructs." \
    "Catches likely bugs with security impact potential." "https://pkg.go.dev/cmd/vet"
  set +e
  go vet ./... > "${REPORT_DIR}/go-vet.txt" 2>&1
  local code=$?
  set -e
  if (( code > 1 )); then echo "go vet execution failed."; exit 1; fi
  echo "$code" > "${REPORT_DIR}/go-vet.exit"
  local findings=0
  if [[ "$code" -ne 0 ]] && [[ -s "${REPORT_DIR}/go-vet.txt" ]]; then findings=$(python3 - <<'PY' "${REPORT_DIR}/go-vet.txt"
import pathlib, sys
path = pathlib.Path(sys.argv[1])
print(sum(1 for line in path.read_text(encoding="utf-8", errors="replace").splitlines() if line.strip()))
PY
); fi
  echo "go vet findings: ${findings} (report: ${REPORT_DIR}/go-vet.txt)"
}

run_clamav() {
  if [[ "$RUN_CLAMAV" != "true" ]]; then
    printf '%s\n' '{"scanned_files":0,"infected_files":0,"exit_code":0,"skipped":true}' > "${REPORT_DIR}/clamav-summary.json"
    : > "${REPORT_DIR}/clamav.log"
    return 0
  fi
  print_tool_header "ClamAV" "Repository malware scan using signature matching." \
    "Optional lane for local workstation hygiene." "https://www.clamav.net/"
  set +e
  clamscan --recursive --infected --exclude-dir='^\.git$' --exclude-dir='^\.security-reports$' --exclude-dir='^bin$' \
    . > "${REPORT_DIR}/clamav.log" 2>&1
  local code=$?
  set -e
  if [[ "$code" -ne 0 && "$code" -ne 1 ]]; then echo "ClamAV execution failed."; exit 1; fi
  python3 - <<'PY' "${REPORT_DIR}/clamav.log" "${REPORT_DIR}/clamav-summary.json" "$code"
import json, pathlib, re, sys
log_path, out_path, code = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), int(sys.argv[3])
text = log_path.read_text(encoding="utf-8", errors="replace") if log_path.exists() else ""
def pick(key):
    match = re.search(rf"{re.escape(key)}:\s+(\d+)", text); return int(match.group(1)) if match else 0
out_path.write_text(json.dumps({"scanned_files": pick("Scanned files"), "infected_files": pick("Infected files"), "exit_code": code}))
PY
}

run_sast_checks() {
  require_command semgrep
  require_command bandit
  require_command pip-audit
  require_command detect-secrets
  require_command gosec
  require_command govulncheck
  require_command go
  require_command python3
  if [[ "$RUN_CLAMAV" == "true" ]]; then require_command clamscan; fi
  run_semgrep
  run_bandit
  run_pip_audit
  run_detect_secrets
  run_gosec
  run_govulncheck
  run_go_vet
  run_clamav
  python3 - <<'PY' "${REPORT_DIR}" "${FAIL_ON_HIGH_CRITICAL}"
import json, pathlib, sys
report_dir = pathlib.Path(sys.argv[1]); fail_on_high = sys.argv[2].lower() == "true"
def read_json(path, default):
    try: return json.loads(path.read_text(encoding="utf-8"))
    except Exception: return default
semgrep = read_json(report_dir / "semgrep.json", {"results": []}).get("results", [])
bandit = read_json(report_dir / "bandit.json", {"results": []}).get("results", [])
pip_audit = read_json(report_dir / "pip-audit.json", {"dependencies": []})
secrets = read_json(report_dir / "detect-secrets.json", {"results": {}}).get("results", {})
gosec = read_json(report_dir / "gosec.json", {"Issues": []}).get("Issues", [])
clamav = read_json(report_dir / "clamav-summary.json", {"infected_files": 0})
govuln_findings = 0
govuln_path = report_dir / "govulncheck.json"
if govuln_path.exists():
    for line in govuln_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line: continue
        try:
            obj = json.loads(line)
            if obj.get("finding"): govuln_findings += 1
        except Exception:
            continue
go_vet_exit = 0
go_vet_exit_path = report_dir / "go-vet.exit"
if go_vet_exit_path.exists():
    try: go_vet_exit = int(go_vet_exit_path.read_text(encoding="utf-8").strip() or "0")
    except Exception: go_vet_exit = 0
go_vet_findings = 0
go_vet_path = report_dir / "go-vet.txt"
if go_vet_path.exists():
    lines = [ln for ln in go_vet_path.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]
    go_vet_findings = len(lines) if go_vet_exit != 0 else 0
semgrep_high = sum(1 for r in semgrep if str(r.get("extra", {}).get("severity", "")).upper() in {"ERROR", "HIGH", "CRITICAL"})
bandit_high = sum(1 for r in bandit if str(r.get("issue_severity", "")).upper() in {"HIGH", "CRITICAL"})
secret_findings = sum(len(v) for v in secrets.values()) if isinstance(secrets, dict) else 0
gosec_high = sum(1 for r in gosec if str(r.get("severity", "")).upper() in {"HIGH", "CRITICAL"})
pip_vulns = 0
for dep in pip_audit.get("dependencies", []):
    if isinstance(dep, dict): pip_vulns += len(dep.get("vulns", []))
high_critical_total = semgrep_high + bandit_high + secret_findings + gosec_high + int(clamav.get("infected_files", 0))
high_critical_total += govuln_findings + go_vet_findings
summary = {
    "semgrep_total": len(semgrep), "semgrep_high_critical": semgrep_high,
    "bandit_total": len(bandit), "bandit_high_critical": bandit_high,
    "pip_audit_dependency_vulns": pip_vulns,
    "detect_secrets_total": secret_findings,
    "gosec_total": len(gosec), "gosec_high_critical": gosec_high,
    "govulncheck_findings": govuln_findings,
    "go_vet_findings": go_vet_findings,
    "clamav_infected_files": int(clamav.get("infected_files", 0)),
    "high_critical_total": high_critical_total,
    "fail_on_high_critical": fail_on_high,
}
(report_dir / "sast-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary, indent=2))
if fail_on_high and high_critical_total > 0:
    print("SAST gate failed: high/critical findings detected.")
    sys.exit(1)
PY
}

if [[ "$RUN_SAST" != "true" ]]; then
  echo "SAST skipped (set RUN_SAST=true to enable)."
  exit 0
fi

echo "Running SAST security checks. Reports: ${REPORT_DIR}"
run_sast_checks
echo "Static Application Security Testing (SAST) checks completed."
echo "Security checks completed successfully. Reports available in ${REPORT_DIR}"
