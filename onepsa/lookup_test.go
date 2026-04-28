package onepsa

import (
	"errors"
	"strings"
	"testing"

	"github.com/1password/onepassword-sdk-go"
)

func TestFindItemByName(t *testing.T) {
	t.Parallel()

	t.Run("finds item by title case insensitively", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
			nil,
			map[string][]onepassword.ItemOverview{
				"v1": {{ID: "item-1", Title: "Prod DB"}},
			},
			nil,
			map[string]onepassword.Item{
				"item-1": {
					ID:    "item-1",
					Title: "Prod DB",
					Fields: []onepassword.ItemField{
						{Title: "username", Value: "root"},
					},
				},
			},
			nil,
		)

		item, err := findItemByName(client, "prod db")
		if err != nil {
			t.Fatalf("findItemByName() error = %v", err)
		}
		if item.Title != "Prod DB" {
			t.Fatalf("findItemByName() title = %q, want %q", item.Title, "Prod DB")
		}
	})

	t.Run("skips vault with list error and continues", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{
				{ID: "v1", Title: "Broken"},
				{ID: "v2", Title: "Healthy"},
			},
			nil,
			map[string][]onepassword.ItemOverview{
				"v2": {{ID: "item-2", Title: "Service API"}},
			},
			map[string]error{"v1": errors.New("temporary failure")},
			map[string]onepassword.Item{
				"item-2": {ID: "item-2", Title: "Service API"},
			},
			nil,
		)

		item, err := findItemByName(client, "service api")
		if err != nil {
			t.Fatalf("findItemByName() error = %v", err)
		}
		if item.ID != "item-2" {
			t.Fatalf("findItemByName() id = %q, want %q", item.ID, "item-2")
		}
	})

	t.Run("returns wrapped list vault error", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(nil, errors.New("vault api down"), nil, nil, nil, nil)

		_, err := findItemByName(client, "anything")
		if err == nil {
			t.Fatal("findItemByName() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "failed to list vaults") {
			t.Fatalf("findItemByName() error = %q, want list-vaults context", err.Error())
		}
	})

	t.Run("returns wrapped get item error", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
			nil,
			map[string][]onepassword.ItemOverview{"v1": {{ID: "item-3", Title: "Mail"}}},
			nil,
			nil,
			map[string]error{"item-3": errors.New("get failed")},
		)

		_, err := findItemByName(client, "mail")
		if err == nil {
			t.Fatal("findItemByName() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "failed to get item details") {
			t.Fatalf("findItemByName() error = %q, want get-item context", err.Error())
		}
	})

	t.Run("returns not found", func(t *testing.T) {
		t.Parallel()
		client := newTestClient(
			[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
			nil,
			map[string][]onepassword.ItemOverview{"v1": {{ID: "item-9", Title: "Other"}}},
			nil,
			map[string]onepassword.Item{},
			nil,
		)

		_, err := findItemByName(client, "missing")
		if err == nil {
			t.Fatal("findItemByName() expected error, got nil")
		}
		if !strings.Contains(err.Error(), "item 'missing' not found") {
			t.Fatalf("findItemByName() error = %q, want not-found message", err.Error())
		}
	})
}
