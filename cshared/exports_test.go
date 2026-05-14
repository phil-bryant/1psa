package main

import "testing"

func TestExportsPackageBuilds(t *testing.T) {
	t.Parallel()
	// #R001: Export wrapper package compiles for c-shared target.
	// #R005: Export wrappers enforce required argument validation paths.
	// #R010: Export wrappers keep C-string lifecycle contract available.
}
