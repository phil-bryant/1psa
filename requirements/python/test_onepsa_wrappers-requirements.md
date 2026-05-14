# python test_onepsa_wrappers Requirements

## Scope

Applies to `python/test_onepsa_wrappers.py`.

R001 Statement: Validate ctypes wrapper behavior for default path and result decoding.
Design: Cover default library path, error-pointer handling, null-output handling, and successful decode/free behavior.
Tests:
- Execute unit tests that exercise `onepsa_ctypes.Onepsa` helper methods.

R005 Statement: Validate cffi wrapper behavior when cffi is available.
Design: Conditionally run cffi-specific unit tests for error handling and successful output conversion.
Tests:
- Execute cffi wrapper tests when dependency is present; skip gracefully otherwise.

R010 Statement: Provide shared-library smoke tests for built dylib availability.
Design: Conditionally run load/argument-validation smoke tests when `bin/libonepsa.dylib` exists.
Tests:
- Verify ctypes/cffi wrappers can load shared library and surface nil-argument validation responses.

## Changelog

- 2026-05-14: Added requirements coverage for `python/test_onepsa_wrappers.py`.
