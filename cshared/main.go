package main

// #R001: Keep package main buildable for c-shared target entrypoint.
// C shared library; entrypoint is unused when loaded via dlopen.
// #R005: Ensure entrypoint performs no runtime side effects.
// #R010: Preserve compatibility with exported cshared wrapper symbols.
func main() {}
