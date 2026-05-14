package main

import (
	"os/exec"
	"strings"
	"testing"
)

func runCLI(t *testing.T, args ...string) (string, error) {
	t.Helper()
	cmd := exec.Command("go", append([]string{"run", "."}, args...)...)
	cmd.Dir = "."
	out, err := cmd.CombinedOutput()
	return string(out), err
}

func TestMain_NoFlags_ShowsUsage(t *testing.T) {
	t.Parallel()
	// #R001: No-flags path shows usage when no command mode is selected.
	out, err := runCLI(t)
	if err != nil {
		t.Fatalf("runCLI() unexpected error: %v\noutput:\n%s", err, out)
	}
	if !strings.Contains(out, "Usage:") {
		t.Fatalf("expected usage output, got:\n%s", out)
	}
}

func TestMain_MultipleFlags_ShowsValidationError(t *testing.T) {
	t.Parallel()
	// #R005: Client-command execution requires exactly one command mode.
	// #R010: Invalid multi-flag invocation keeps stable error and usage output.
	out, err := runCLI(t, "-l", "-u", "my-item")
	if err != nil {
		t.Fatalf("runCLI() unexpected error: %v\noutput:\n%s", err, out)
	}
	if !strings.Contains(out, "Error: Only one flag can be used at a time") {
		t.Fatalf("expected single-flag validation error, got:\n%s", out)
	}
	if !strings.Contains(out, "Usage:") {
		t.Fatalf("expected usage output, got:\n%s", out)
	}
}
