from __future__ import annotations

import ctypes
from pathlib import Path
from typing import Optional


class OnepsaError(RuntimeError):
    pass


class Onepsa:
    def __init__(self, lib_path: Optional[str] = None) -> None:
        #R001: Resolve repository-default shared library path when not provided.
        if lib_path is None:
            lib_path = str(Path(__file__).resolve().parents[1] / "bin" / "libonepsa.dylib")

        #R005: Load shared library and configure ctypes signatures for exports.
        self._lib = ctypes.CDLL(lib_path)

        self._lib.OnepsaStringFree.argtypes = [ctypes.c_void_p]
        self._lib.OnepsaStringFree.restype = None

        self._lib.OnepsaListAll.argtypes = [ctypes.POINTER(ctypes.c_char_p)]
        self._lib.OnepsaListAll.restype = ctypes.c_void_p

        self._lib.OnepsaListFields.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p)]
        self._lib.OnepsaListFields.restype = ctypes.c_void_p

        self._lib.OnepsaGetField.argtypes = [
            ctypes.c_char_p,
            ctypes.c_char_p,
            ctypes.POINTER(ctypes.c_char_p),
        ]
        self._lib.OnepsaGetField.restype = ctypes.c_void_p

        self._lib.OnepsaGetMulti.argtypes = [
            ctypes.c_char_p,
            ctypes.c_char_p,
            ctypes.POINTER(ctypes.c_char_p),
        ]
        self._lib.OnepsaGetMulti.restype = ctypes.c_void_p

    def list_all(self) -> str:
        return self._call0(self._lib.OnepsaListAll)

    def list_fields(self, item: str) -> str:
        return self._call1(self._lib.OnepsaListFields, item)

    def get_field(self, item: str, field: str) -> str:
        return self._call2(self._lib.OnepsaGetField, item, field)

    def get_multi(self, item: str, fields_csv: str) -> str:
        return self._call2(self._lib.OnepsaGetMulti, item, fields_csv)

    def _call0(self, fn) -> str:
        err = ctypes.c_char_p()
        out_ptr = fn(ctypes.byref(err))
        return self._consume_result(out_ptr, err)

    def _call1(self, fn, a: str) -> str:
        err = ctypes.c_char_p()
        out_ptr = fn(a.encode("utf-8"), ctypes.byref(err))
        return self._consume_result(out_ptr, err)

    def _call2(self, fn, a: str, b: str) -> str:
        err = ctypes.c_char_p()
        out_ptr = fn(a.encode("utf-8"), b.encode("utf-8"), ctypes.byref(err))
        return self._consume_result(out_ptr, err)

    def _consume_result(self, out_ptr, err: ctypes.c_char_p) -> str:
        #R010: Convert pointer results into decoded strings or explicit errors.
        if err.value is not None:
            msg = err.value.decode("utf-8")
            self._lib.OnepsaStringFree(err)
            raise OnepsaError(msg)

        if not out_ptr:
            raise OnepsaError("onepsa returned null without error")

        out = ctypes.cast(out_ptr, ctypes.c_char_p).value
        self._lib.OnepsaStringFree(out_ptr)

        if out is None:
            return ""
        return out.decode("utf-8")


if __name__ == "__main__":
    client = Onepsa()
    print(client.list_all())
