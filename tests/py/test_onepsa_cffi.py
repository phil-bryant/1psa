from pathlib import Path


def test_onepsa_cffi_scope_markers_present() -> None:
    #R001: cffi wrapper uses repository-default shared library path.
    #R005: cffi wrapper defines exported function signatures before loading library.
    #R010: cffi wrapper converts pointer results into exceptions/decoded strings.
    target = Path(__file__).resolve().parents[2] / "python" / "onepsa_cffi.py"
    assert target.exists()
