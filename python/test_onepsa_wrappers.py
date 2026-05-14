from __future__ import annotations

import ctypes
import importlib.util
import unittest
from pathlib import Path
from unittest import mock

import onepsa_ctypes

if importlib.util.find_spec("cffi") is not None:
    import onepsa_cffi
else:
    onepsa_cffi = None


class _FakeCtypesLib:
    def __init__(self) -> None:
        self.freed = []

    def OnepsaStringFree(self, ptr) -> None:
        self.freed.append(ptr)


class CtypesWrapperTests(unittest.TestCase):
    #R001: Validate ctypes wrapper default-path and decode/error helper behavior.
    def test_default_library_path_is_used(self) -> None:
        with mock.patch("onepsa_ctypes.ctypes.CDLL") as cdll:
            onepsa_ctypes.Onepsa()
            (path_arg,), _ = cdll.call_args
            self.assertTrue(str(path_arg).endswith("bin/libonepsa.dylib"))

    def test_consume_result_raises_on_error_pointer(self) -> None:
        client = onepsa_ctypes.Onepsa.__new__(onepsa_ctypes.Onepsa)
        client._lib = _FakeCtypesLib()
        err = ctypes.c_char_p(b"boom")

        with self.assertRaises(onepsa_ctypes.OnepsaError) as ctx:
            client._consume_result(ctypes.c_void_p(), err)

        self.assertIn("boom", str(ctx.exception))
        self.assertEqual(1, len(client._lib.freed))

    def test_consume_result_raises_on_null_without_error(self) -> None:
        client = onepsa_ctypes.Onepsa.__new__(onepsa_ctypes.Onepsa)
        client._lib = _FakeCtypesLib()

        with self.assertRaises(onepsa_ctypes.OnepsaError) as ctx:
            client._consume_result(ctypes.c_void_p(), ctypes.c_char_p())

        self.assertIn("null without error", str(ctx.exception))

    def test_consume_result_decodes_and_frees_output(self) -> None:
        client = onepsa_ctypes.Onepsa.__new__(onepsa_ctypes.Onepsa)
        client._lib = _FakeCtypesLib()
        buf = ctypes.create_string_buffer(b"hello")
        out_ptr = ctypes.cast(buf, ctypes.c_void_p)

        out = client._consume_result(out_ptr, ctypes.c_char_p())

        self.assertEqual("hello", out)
        self.assertEqual([out_ptr], client._lib.freed)


@unittest.skipIf(onepsa_cffi is None, "cffi is not installed")
class CffiWrapperTests(unittest.TestCase):
    #R005: Validate cffi wrapper decode/error behavior when dependency is available.
    class _FakeLib:
        def __init__(self) -> None:
            self.freed = []

        def OnepsaStringFree(self, ptr) -> None:
            self.freed.append(ptr)

    class _FakeFFI:
        NULL = object()

        @staticmethod
        def string(ptr):
            return ptr

    def test_consume_result_raises_on_error_pointer(self) -> None:
        client = onepsa_cffi.Onepsa.__new__(onepsa_cffi.Onepsa)
        client._ffi = self._FakeFFI()
        client._lib = self._FakeLib()

        with self.assertRaises(onepsa_cffi.OnepsaError) as ctx:
            client._consume_result(self._FakeFFI.NULL, [b"boom"])

        self.assertIn("boom", str(ctx.exception))
        self.assertEqual([b"boom"], client._lib.freed)

    def test_consume_result_raises_on_null_without_error(self) -> None:
        client = onepsa_cffi.Onepsa.__new__(onepsa_cffi.Onepsa)
        client._ffi = self._FakeFFI()
        client._lib = self._FakeLib()

        with self.assertRaises(onepsa_cffi.OnepsaError) as ctx:
            client._consume_result(self._FakeFFI.NULL, [self._FakeFFI.NULL])

        self.assertIn("null without error", str(ctx.exception))

    def test_consume_result_returns_text_and_frees_out(self) -> None:
        client = onepsa_cffi.Onepsa.__new__(onepsa_cffi.Onepsa)
        client._ffi = self._FakeFFI()
        client._lib = self._FakeLib()

        out = client._consume_result(b"value", [self._FakeFFI.NULL])

        self.assertEqual("value", out)
        self.assertEqual([b"value"], client._lib.freed)


class SharedLibraryLoadSmokeTests(unittest.TestCase):
    #R010: Run conditional shared-library load and argument-validation smoke tests.
    @staticmethod
    def _default_lib_path() -> Path:
        return Path(__file__).resolve().parents[1] / "bin" / "libonepsa.dylib"

    @unittest.skipUnless(_default_lib_path.__func__().exists(), "shared library not built")
    def test_ctypes_can_load_built_shared_library(self) -> None:
        client = onepsa_ctypes.Onepsa(str(self._default_lib_path()))
        self.assertIsNotNone(client._lib)

    @unittest.skipUnless(_default_lib_path.__func__().exists(), "shared library not built")
    def test_shared_library_validates_nil_arguments(self) -> None:
        lib = ctypes.CDLL(str(self._default_lib_path()))
        lib.OnepsaStringFree.argtypes = [ctypes.c_void_p]
        lib.OnepsaStringFree.restype = None

        lib.OnepsaListFields.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p)]
        lib.OnepsaListFields.restype = ctypes.c_void_p
        err = ctypes.c_char_p()
        out = lib.OnepsaListFields(None, ctypes.byref(err))
        self.assertFalse(out)
        self.assertEqual("item is required", err.value.decode("utf-8"))
        lib.OnepsaStringFree(err)

        lib.OnepsaGetField.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p)]
        lib.OnepsaGetField.restype = ctypes.c_void_p
        err = ctypes.c_char_p()
        out = lib.OnepsaGetField(ctypes.c_char_p(b"item"), None, ctypes.byref(err))
        self.assertFalse(out)
        self.assertEqual("field is required", err.value.decode("utf-8"))
        lib.OnepsaStringFree(err)

    @unittest.skipIf(onepsa_cffi is None, "cffi is not installed")
    @unittest.skipUnless(_default_lib_path.__func__().exists(), "shared library not built")
    def test_cffi_can_load_built_shared_library(self) -> None:
        client = onepsa_cffi.Onepsa(str(self._default_lib_path()))
        self.assertIsNotNone(client._lib)


if __name__ == "__main__":
    unittest.main()
