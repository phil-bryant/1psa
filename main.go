package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/1password/onepassword-sdk-go"
)

func main() {
	// Define flags
	listFlag := flag.Bool("l", false, "List credentials available in vaults (optionally specify item name)")
	fieldFlag := flag.Bool("f", false, "Get specific field value from item (requires item and field name)")
	usernameFlag := flag.String("u", "", "Get username field from item")
	passwordFlag := flag.String("p", "", "Get password field from item")

	flag.Parse()

	// Get remaining arguments
	args := flag.Args()

	// Validate flag combinations
	flagCount := 0
	if *listFlag {
		flagCount++
	}
	if *fieldFlag {
		flagCount++
	}
	if *usernameFlag != "" {
		flagCount++
	}
	if *passwordFlag != "" {
		flagCount++
	}

	if flagCount == 0 {
		showUsage()
		return
	}

	if flagCount > 1 {
		fmt.Println("Error: Only one flag can be used at a time")
		showUsage()
		return
	}

	// Create 1Password client
	client, err := createClient()
	if err != nil {
		log.Fatalf("Failed to create 1Password client: %v", err)
	}

	// Handle different flags
	if *listFlag {
		var itemName string
		if len(args) > 0 {
			itemName = args[0]
		}
		err = handleListCommand(client, itemName)
	} else if *fieldFlag {
		if len(args) < 2 {
			fmt.Println("Error: -f flag requires both item name and field name")
			showUsage()
			return
		}
		err = handleFieldCommand(client, args[0], args[1])
	} else if *usernameFlag != "" {
		err = handleFieldCommand(client, *usernameFlag, "username")
	} else if *passwordFlag != "" {
		err = handleFieldCommand(client, *passwordFlag, "password")
	}

	if err != nil {
		log.Fatalf("Command failed: %v", err)
	}
}

func showUsage() {
	fmt.Println("Usage:")
	fmt.Println("  1psa -l [item_name]         List credentials (optionally for specific item)")
	fmt.Println("  1psa -f item_name field     Get specific field value from item")
	fmt.Println("  1psa -u item_name           Get username from item")
	fmt.Println("  1psa -p item_name           Get password from item")
}

func createClient() (*onepassword.Client, error) {
	// Read the service account token from ~/.1psa
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get user home directory: %w", err)
	}

	tokenPath := filepath.Join(homeDir, ".1psa")
	tokenBytes, err := os.ReadFile(tokenPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read service account token from %s: %w", tokenPath, err)
	}

	// Clean the token (remove any whitespace/newlines)
	token := strings.TrimSpace(string(tokenBytes))

	// Create a 1Password client
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

func handleListCommand(client *onepassword.Client, itemName string) error {
	ctx := context.TODO()

	if itemName != "" {
		// List fields for specific item
		return listItemFields(client, itemName)
	}

	// List all credentials
	vaults, err := client.Vaults().List(ctx)
	if err != nil {
		return fmt.Errorf("failed to list vaults: %w", err)
	}

	if len(vaults) == 0 {
		fmt.Println("No vaults accessible to this service account")
		return nil
	}

	fmt.Printf("Found %d vault(s) accessible to the service account:\n\n", len(vaults))

	// Iterate through each vault and list items
	for _, vault := range vaults {
		fmt.Printf("Vault: %s (ID: %s)\n", vault.Title, vault.ID)
		fmt.Println(strings.Repeat("-", len(vault.Title)+20))

		items, err := client.Items().List(ctx, vault.ID)
		if err != nil {
			fmt.Printf("  Error listing items in vault %s: %v\n\n", vault.Title, err)
			continue
		}

		if len(items) == 0 {
			fmt.Println("  No items found in this vault")
		} else {
			fmt.Printf("  Found %d item(s):\n", len(items))
			for i, item := range items {
				// Format: "1. odus (ID: 6b5v7dgm2zc6l447vgs5uabvd4) Category: Login"
				categoryStr := ""
				if item.Category != "" {
					categoryStr = fmt.Sprintf(" Category: %s", item.Category)
				}
				tagsStr := ""
				if len(item.Tags) > 0 {
					tagsStr = fmt.Sprintf(" Tags: %s", strings.Join(item.Tags, ", "))
				}
				fmt.Printf("  %d. %s (ID: %s)%s%s\n", i+1, item.Title, item.ID, categoryStr, tagsStr)
			}
		}
		fmt.Println()
	}

	return nil
}

func listItemFields(client *onepassword.Client, itemName string) error {
	item, err := findItemByName(client, itemName)
	if err != nil {
		return err
	}

	fmt.Printf("Fields for item '%s':\n", item.Title)
	fmt.Println(strings.Repeat("-", len(item.Title)+20))

	if len(item.Fields) == 0 {
		fmt.Println("No fields found in this item")
		return nil
	}

	for i, field := range item.Fields {
		fmt.Printf("%d. %s\n", i+1, field.Title)
	}

	return nil
}

func handleFieldCommand(client *onepassword.Client, itemName, fieldName string) error {
	item, err := findItemByName(client, itemName)
	if err != nil {
		return err
	}

	// Look for the field
	for _, field := range item.Fields {
		if strings.EqualFold(field.Title, fieldName) {
			fmt.Println(field.Value)
			return nil
		}
	}

	return fmt.Errorf("field '%s' not found in item '%s'", fieldName, itemName)
}

func findItemByName(client *onepassword.Client, itemName string) (*onepassword.Item, error) {
	ctx := context.TODO()

	// List all vaults
	vaults, err := client.Vaults().List(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list vaults: %w", err)
	}

	// Search through all vaults for the item
	for _, vault := range vaults {
		items, err := client.Items().List(ctx, vault.ID)
		if err != nil {
			continue // Skip vaults we can't access
		}

		for _, itemOverview := range items {
			if strings.EqualFold(itemOverview.Title, itemName) {
				// Found the item, now get the full item details
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
