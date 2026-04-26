package onepsa

import (
	"fmt"
	"strings"

	"github.com/1password/onepassword-sdk-go"
)

// GetFieldValueText returns a single field value (same as CLI -f / -u / -p), without a trailing newline.
func GetFieldValueText(client *onepassword.Client, itemName, fieldName string) (string, error) {
	item, err := findItemByName(client, itemName)
	if err != nil {
		return "", err
	}

	value, found := getFieldValue(item, fieldName)
	if !found {
		return "", fmt.Errorf("field '%s' not found in item '%s'", fieldName, itemName)
	}

	return value, nil
}

// GetMultiFieldText returns "key=value\n" lines (same as CLI -m).
func GetMultiFieldText(client *onepassword.Client, itemName string, requestedFields []string) (string, error) {
	item, err := findItemByName(client, itemName)
	if err != nil {
		return "", err
	}

	fields := normalizeRequestedFields(requestedFields)
	if len(fields) == 0 {
		return "", fmt.Errorf("no field names provided")
	}

	var b strings.Builder
	var missing []string
	for _, fieldName := range fields {
		value, found := getFieldValue(item, fieldName)
		if !found {
			missing = append(missing, fieldName)
			continue
		}
		fmt.Fprintf(&b, "%s=%s\n", fieldName, value)
	}

	if len(missing) > 0 {
		return "", fmt.Errorf("field(s) %s not found in item '%s'", strings.Join(missing, ", "), itemName)
	}

	return b.String(), nil
}

func normalizeRequestedFields(input []string) []string {
	var fields []string
	for _, token := range input {
		for _, part := range strings.Split(token, ",") {
			field := strings.TrimSpace(part)
			if field == "" {
				continue
			}
			fields = append(fields, field)
		}
	}
	return fields
}

func getFieldValue(item *onepassword.Item, fieldName string) (string, bool) {
	for _, field := range item.Fields {
		if strings.EqualFold(field.Title, fieldName) {
			return field.Value, true
		}
	}
	return "", false
}
