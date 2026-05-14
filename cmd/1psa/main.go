package main

import (
	"flag"
	"fmt"
	"log"

	"1psa/onepsa"
)

func main() {
	// #R001: Parse flags and enforce exactly one command mode.
	listFlag := flag.Bool("l", false, "List credentials available in vaults (optionally specify item name)")
	fieldFlag := flag.Bool("f", false, "Get specific field value from item (requires item and field name)")
	multiFieldFlag := flag.Bool("m", false, "Get multiple field values from item (requires item and one or more field names)")
	usernameFlag := flag.String("u", "", "Get username field from item")
	passwordFlag := flag.String("p", "", "Get password field from item")

	flag.Parse()
	args := flag.Args()

	flagCount := 0
	if *listFlag {
		flagCount++
	}
	if *fieldFlag {
		flagCount++
	}
	if *multiFieldFlag {
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

	// #R005: Initialize the onepsa client before handling command routing.
	client, err := onepsa.CreateClient()
	if err != nil {
		log.Fatalf("Failed to create 1Password client: %v", err)
	}

	// #R010: Route each command mode to the matching onepsa text helper.
	var out string
	if *listFlag {
		var itemName string
		if len(args) > 0 {
			itemName = args[0]
		}
		if itemName != "" {
			out, err = onepsa.ListItemFieldsText(client, itemName)
		} else {
			out, err = onepsa.ListAllCredentialsText(client)
		}
	} else if *fieldFlag {
		if len(args) < 2 {
			fmt.Println("Error: -f flag requires both item name and field name")
			showUsage()
			return
		}
		out, err = onepsa.GetFieldValueText(client, args[0], args[1])
	} else if *multiFieldFlag {
		if len(args) < 2 {
			fmt.Println("Error: -m flag requires item name and one or more field names")
			showUsage()
			return
		}
		out, err = onepsa.GetMultiFieldText(client, args[0], args[1:])
	} else if *usernameFlag != "" {
		out, err = onepsa.GetFieldValueText(client, *usernameFlag, "username")
	} else {
		out, err = onepsa.GetFieldValueText(client, *passwordFlag, "password")
	}

	if err != nil {
		log.Fatalf("Command failed: %v", err)
	}
	if *listFlag || *multiFieldFlag {
		fmt.Print(out)
	} else {
		fmt.Println(out)
	}
}

func showUsage() {
	fmt.Println("Usage:")
	fmt.Println("  1psa -l [item_name]         List credentials (optionally for specific item)")
	fmt.Println("  1psa -f item_name field     Get specific field value from item")
	fmt.Println("  1psa -m item_name fields... Get multiple field values in one call")
	fmt.Println("  1psa -u item_name           Get username from item")
	fmt.Println("  1psa -p item_name           Get password from item")
}
