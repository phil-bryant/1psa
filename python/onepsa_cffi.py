from __future__ import annotations

from pathlib import Path
from typing import Optional

from cffi import FFI


class OnepsaError(RuntimeError):
    pass


class Onepsa:
    def __init__(self, lib_path: Optional[str] = None) -> None:
        #R001: Resolve repository-default shared library path when not provided.
        if lib_path is None:
            lib_path = str(Path(__file__).resolve().parents[1] / "bin" / "libonepsa.dylib")

        self._ffi = FFI()
        #R005: Define cffi signatures for exported onepsa C functions.
        self._ffi.cdef(
            """
            void OnepsaStringFree(char* p);
            char* OnepsaListAll(char** errOut);
            char* OnepsaListFields(char* item, char** errOut);
            char* OnepsaGetField(char* item, char* field, char** errOut);
            char* OnepsaGetMulti(char* item, char* fields, char** errOut);
            """
        )
        self._lib = self._ffi.dlopen(lib_path)

    def list_all(self) -> str:
        return self._call0(self._lib.OnepsaListAll)

    def list_fields(self, item: str) -> str:
        return self._call1(self._lib.OnepsaListFields, item)

    def get_field(self, item: str, field: str) -> str:
        return self._call2(self._lib.OnepsaGetField, item, field)

    def get_multi(self, item: str, fields_csv: str) -> str:
        return self._call2(self._lib.OnepsaGetMulti, item, fields_csv)

    def _call0(self, fn) -> str:
        err = self._ffi.new("char**")
        out = fn(err)
        return self._consume_result(out, err)

    def _call1(self, fn, a: str) -> str:
        err = self._ffi.new("char**")
        out = fn(self._ffi.new("char[]", a.encode("utf-8")), err)
        return self._consume_result(out, err)

    def _call2(self, fn, a: str, b: str) -> str:
        err = self._ffi.new("char**")
        out = fn(
            self._ffi.new("char[]", a.encode("utf-8")),
            self._ffi.new("char[]", b.encode("utf-8")),
            err,
        )
        return self._consume_result(out, err)

    def _consume_result(self, out, err_ptr) -> str:
        #R010: Convert error/output pointers into exceptions or decoded strings.
        err = err_ptr[0]
        if err != self._ffi.NULL:
            msg = self._ffi.string(err).decode("utf-8")
            self._lib.OnepsaStringFree(err)
            raise OnepsaError(msg)

        if out == self._ffi.NULL:
            raise OnepsaError("onepsa returned null without error")

        value = self._ffi.string(out).decode("utf-8")
        self._lib.OnepsaStringFree(out)
        return value


if __name__ == "__main__":
    client = Onepsa()
    print(client.list_all())
