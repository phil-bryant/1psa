package onepsa

import (
	"errors"
	"strings"
	"testing"

	"github.com/1password/onepassword-sdk-go"
)

func TestListItemFieldsText(t *testing.T) {
	t.Parallel()

	t.Run("validates empty item name", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(nil, nil, nil, nil, nil, nil)
		_, err := ListItemFieldsText(client, "   ")
		if err == nil {
			t.Fatal("ListItemFieldsText() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "item name is required") {
			t.Fatalf("ListItemFieldsText() error = %q, want required-item error", err.Error())
		}
	})

	t.Run("formats fields for item", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
			nil,
			map[string][]onepassword.ItemOverview{"v1": {{ID: "item-1", Title: "Database"}}},
			nil,
			map[string]onepassword.Item{
				"item-1": {
					ID:    "item-1",
					Title: "Database",
					Fields: []onepassword.ItemField{
						{Title: "username"},
						{Title: "password"},
					},
				},
			},
			nil,
		)

		got, err := ListItemFieldsText(client, "database")
		if err != nil {
			t.Fatalf("ListItemFieldsText() error = %v", err)
		}
		if !strings.Contains(got, "Fields for item 'Database':") {
			t.Fatalf("ListItemFieldsText() output missing header: %q", got)
		}
		if !strings.Contains(got, "1. username") || !strings.Contains(got, "2. password") {
			t.Fatalf("ListItemFieldsText() output missing expected fields: %q", got)
		}
	})

	t.Run("handles item with no fields", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
			nil,
			map[string][]onepassword.ItemOverview{"v1": {{ID: "item-2", Title: "Empty"}}},
			nil,
			map[string]onepassword.Item{
				"item-2": {ID: "item-2", Title: "Empty"},
			},
			nil,
		)

		got, err := ListItemFieldsText(client, "empty")
		if err != nil {
			t.Fatalf("ListItemFieldsText() error = %v", err)
		}
		if !strings.Contains(got, "No fields found in this item") {
			t.Fatalf("ListItemFieldsText() output missing empty-item message: %q", got)
		}
	})
}

func TestListAllCredentialsText(t *testing.T) {
	t.Parallel()

	t.Run("handles no vaults", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(nil, nil, nil, nil, nil, nil)

		got, err := ListAllCredentialsText(client)
		if err != nil {
			t.Fatalf("ListAllCredentialsText() error = %v", err)
		}
		if got != "No vaults accessible to this service account" {
			t.Fatalf("ListAllCredentialsText() = %q", got)
		}
	})

	t.Run("renders vaults and items", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
			nil,
			map[string][]onepassword.ItemOverview{
				"v1": {{ID: "item-1", Title: "Database", Category: "Login", Tags: []string{"prod", "db"}}},
			},
			nil,
			nil,
			nil,
		)

		got, err := ListAllCredentialsText(client)
		if err != nil {
			t.Fatalf("ListAllCredentialsText() error = %v", err)
		}
		if !strings.Contains(got, "Found 1 vault(s)") {
			t.Fatalf("ListAllCredentialsText() output missing vault count: %q", got)
		}
		if !strings.Contains(got, "Vault: Main (ID: v1)") {
			t.Fatalf("ListAllCredentialsText() output missing vault header: %q", got)
		}
		if !strings.Contains(got, "1. Database (ID: item-1) Category: Login Tags: prod, db") {
			t.Fatalf("ListAllCredentialsText() output missing item details: %q", got)
		}
	})

	t.Run("reports vault list failure", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(nil, errors.New("network down"), nil, nil, nil, nil)
		_, err := ListAllCredentialsText(client)
		if err == nil {
			t.Fatal("ListAllCredentialsText() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "failed to list vaults") {
			t.Fatalf("ListAllCredentialsText() error = %q, want list-vaults context", err.Error())
		}
	})

	t.Run("renders item list error inline and continues", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{
				{ID: "v1", Title: "Main"},
				{ID: "v2", Title: "Empty"},
			},
			nil,
			map[string][]onepassword.ItemOverview{
				"v2": {},
			},
			map[string]error{"v1": errors.New("forbidden")},
			nil,
			nil,
		)

		got, err := ListAllCredentialsText(client)
		if err != nil {
			t.Fatalf("ListAllCredentialsText() error = %v", err)
		}
		if !strings.Contains(got, "Error listing items in vault Main: forbidden") {
			t.Fatalf("ListAllCredentialsText() output missing list error: %q", got)
		}
		if !strings.Contains(got, "No items found in this vault") {
			t.Fatalf("ListAllCredentialsText() output missing empty-vault message: %q", got)
		}
	})
}
