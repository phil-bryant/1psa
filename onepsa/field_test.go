package onepsa

import (
	"reflect"
	"testing"

	"github.com/1password/onepassword-sdk-go"
)

func TestNormalizeRequestedFields(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name  string
		input []string
		want  []string
	}{
		{
			name:  "handles comma separated and trimmed entries",
			input: []string{" username,password ", "server"},
			want:  []string{"username", "password", "server"},
		},
		{
			name:  "drops empty tokens",
			input: []string{"username,,", "  ", ",password"},
			want:  []string{"username", "password"},
		},
		{
			name:  "returns nil for empty input",
			input: nil,
			want:  nil,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			got := normalizeRequestedFields(tt.input)
			if !reflect.DeepEqual(got, tt.want) {
				t.Fatalf("normalizeRequestedFields() = %#v, want %#v", got, tt.want)
			}
		})
	}
}

func TestGetFieldValue(t *testing.T) {
	t.Parallel()

	item := &onepassword.Item{
		Fields: []onepassword.ItemField{
			{Title: "username", Value: "alice"},
			{Title: "Password", Value: "s3cr3t"},
		},
	}

	tests := []struct {
		name      string
		fieldName string
		want      string
		found     bool
	}{
		{name: "exact match", fieldName: "username", want: "alice", found: true},
		{name: "case insensitive match", fieldName: "password", want: "s3cr3t", found: true},
		{name: "missing field", fieldName: "server", found: false},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			got, found := getFieldValue(item, tt.fieldName)
			if found != tt.found {
				t.Fatalf("getFieldValue() found = %v, want %v", found, tt.found)
			}
			if got != tt.want {
				t.Fatalf("getFieldValue() got = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestGetMultiFieldText(t *testing.T) {
	t.Parallel()

	client := newTestClient(
		[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
		nil,
		map[string][]onepassword.ItemOverview{
			"v1": {{ID: "i1", Title: "DB"}},
		},
		nil,
		map[string]onepassword.Item{
			"i1": {
				ID:    "i1",
				Title: "DB",
				Fields: []onepassword.ItemField{
					{Title: "username", Value: "root"},
					{Title: "password", Value: "hunter2"},
				},
			},
		},
		nil,
	)

	got, err := GetMultiFieldText(client, "db", []string{"username,password"})
	if err != nil {
		t.Fatalf("GetMultiFieldText() error = %v", err)
	}

	const want = "username=root\npassword=hunter2\n"
	if got != want {
		t.Fatalf("GetMultiFieldText() = %q, want %q", got, want)
	}
}

func TestGetFieldValueText(t *testing.T) {
	t.Parallel()

	client := newTestClient(
		[]onepassword.VaultOverview{{ID: "v1", Title: "Main"}},
		nil,
		map[string][]onepassword.ItemOverview{"v1": {{ID: "i1", Title: "DB"}}},
		nil,
		map[string]onepassword.Item{
			"i1": {
				ID:    "i1",
				Title: "DB",
				Fields: []onepassword.ItemField{
					{Title: "username", Value: "root"},
				},
			},
		},
		nil,
	)

	got, err := GetFieldValueText(client, "db", "username")
	if err != nil {
		t.Fatalf("GetFieldValueText() error = %v", err)
	}
	if got != "root" {
		t.Fatalf("GetFieldValueText() = %q, want %q", got, "root")
	}

	_, err = GetFieldValueText(client, "db", "password")
	if err == nil {
		t.Fatal("GetFieldValueText() expected missing-field error, got nil")
	}
}
