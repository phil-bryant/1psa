package onepsa

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/1password/onepassword-sdk-go"
)

// CreateClient reads the service account token from ~/.1psa and returns a 1Password client.
func CreateClient() (*onepassword.Client, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get user home directory: %w", err)
	}

	tokenPath := filepath.Join(homeDir, ".1psa")
	return CreateClientWithTokenPath(tokenPath)
}

// CreateClientWithTokenPath reads the service account token from the given file path.
func CreateClientWithTokenPath(tokenPath string) (*onepassword.Client, error) {
	// #nosec G304 -- caller controls token path for testability and alternate local token locations.
	tokenBytes, err := os.ReadFile(tokenPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read service account token from %s: %w", tokenPath, err)
	}

	token := strings.TrimSpace(string(tokenBytes))

	client, err := onepassword.NewClient(
		context.TODO(),
		onepassword.WithServiceAccountToken(token),
		onepassword.WithIntegrationInfo("1psa", "v1.0.0"),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create client: %w", err)
	}

	return client, nil
}
