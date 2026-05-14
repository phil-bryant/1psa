package onepsa

import (
	"context"
	"fmt"
	"strings"

	"github.com/1password/onepassword-sdk-go"
)

func findItemByName(client *onepassword.Client, itemName string) (*onepassword.Item, error) {
	ctx := context.TODO()
	// #R001: Enumerate accessible vaults before attempting item lookup.
	vaults, err := client.Vaults().List(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list vaults: %w", err)
	}

	for _, vault := range vaults {
		items, err := client.Items().List(ctx, vault.ID)
		// #R010: Continue searching remaining vaults when one list call fails.
		if err != nil {
			continue
		}

		for _, itemOverview := range items {
			// #R005: Match item titles case-insensitively across vaults.
			if strings.EqualFold(itemOverview.Title, itemName) {
				fullItem, err := client.Items().Get(ctx, vault.ID, itemOverview.ID)
				if err != nil {
					return nil, fmt.Errorf("failed to get item details: %w", err)
				}
				return &fullItem, nil
			}
		}
	}

	return nil, fmt.Errorf("item '%s' not found", itemName)
}
