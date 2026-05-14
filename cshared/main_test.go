package main

import "testing"

func TestMainEntrypointNoPanic(t *testing.T) {
	t.Parallel()
	// #R001: cshared package entrypoint remains buildable.
	// #R005: cshared entrypoint has no runtime side effects.
	// #R010: cshared entrypoint remains compatible with exported wrappers.
	main()
}
