package onepsa

import (
	"context"
	"fmt"
	"strings"

	"github.com/1password/onepassword-sdk-go"
)

// ListAllCredentialsText returns the same text the CLI prints for "list all" (no item name).
func ListAllCredentialsText(client *onepassword.Client) (string, error) {
	return formatListAll(client)
}

// ListItemFieldsText returns the same text the CLI prints for "list" with a specific item name.
func ListItemFieldsText(client *onepassword.Client, itemName string) (string, error) {
	// #R001: Reject blank item names before performing lookups.
	if strings.TrimSpace(itemName) == "" {
		return "", fmt.Errorf("item name is required")
	}
	return formatItemFields(client, itemName)
}

// #R005: Render deterministic text output for vault/item listings.
func formatListAll(client *onepassword.Client) (string, error) {
	var b strings.Builder
	ctx := context.TODO()
	vaults, err := client.Vaults().List(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to list vaults: %w", err)
	}

	if len(vaults) == 0 {
		b.WriteString("No vaults accessible to this service account")
		return b.String(), nil
	}

	fmt.Fprintf(&b, "Found %d vault(s) accessible to the service account:\n\n", len(vaults))

	for _, vault := range vaults {
		fmt.Fprintf(&b, "Vault: %s (ID: %s)\n", vault.Title, vault.ID)
		b.WriteString(strings.Repeat("-", len(vault.Title)+20))
		b.WriteByte('\n')

		items, err := client.Items().List(ctx, vault.ID)
		// #R010: Continue rendering when a vault item-list call fails.
		if err != nil {
			fmt.Fprintf(&b, "  Error listing items in vault %s: %v\n\n", vault.Title, err)
			continue
		}

		if len(items) == 0 {
			b.WriteString("  No items found in this vault\n")
		} else {
			fmt.Fprintf(&b, "  Found %d item(s):\n", len(items))
			for i, item := range items {
				categoryStr := ""
				if item.Category != "" {
					categoryStr = fmt.Sprintf(" Category: %s", item.Category)
				}
				tagsStr := ""
				if len(item.Tags) > 0 {
					tagsStr = fmt.Sprintf(" Tags: %s", strings.Join(item.Tags, ", "))
				}
				fmt.Fprintf(&b, "  %d. %s (ID: %s)%s%s\n", i+1, item.Title, item.ID, categoryStr, tagsStr)
			}
		}
		b.WriteByte('\n')
	}

	return b.String(), nil
}

func formatItemFields(client *onepassword.Client, itemName string) (string, error) {
	item, err := findItemByName(client, itemName)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	fmt.Fprintf(&b, "Fields for item '%s':\n", item.Title)
	b.WriteString(strings.Repeat("-", len(item.Title)+20))
	b.WriteByte('\n')

	if len(item.Fields) == 0 {
		b.WriteString("No fields found in this item")
		return b.String(), nil
	}

	for i, field := range item.Fields {
		fmt.Fprintf(&b, "%d. %s\n", i+1, field.Title)
	}

	return b.String(), nil
}
