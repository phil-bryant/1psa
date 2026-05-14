package onepsa

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCreateClientWithTokenPath(t *testing.T) {
	t.Parallel()
	// #R001: Client resolves default token location requirements.
	// #R005: Client trims token content before SDK setup.
	// #R010: Client returns wrapped error context on failures.

	t.Run("returns useful error when token file missing", func(t *testing.T) {
		t.Parallel()
		_, err := CreateClientWithTokenPath(filepath.Join(t.TempDir(), "missing-token"))
		if err == nil {
			t.Fatal("CreateClientWithTokenPath() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "failed to read service account token") {
			t.Fatalf("CreateClientWithTokenPath() error = %q, want read-token context", err.Error())
		}
	})

	t.Run("trims token file before client creation", func(t *testing.T) {
		t.Parallel()
		tokenFile := filepath.Join(t.TempDir(), ".1psa")
		if err := os.WriteFile(tokenFile, []byte("  \n\t"), 0o600); err != nil {
			t.Fatalf("os.WriteFile() error = %v", err)
		}

		_, err := CreateClientWithTokenPath(tokenFile)
		if err == nil {
			t.Fatal("CreateClientWithTokenPath() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "failed to create client") {
			t.Fatalf("CreateClientWithTokenPath() error = %q, want create-client context", err.Error())
		}
	})
}
