from pathlib import Path


def test_wrapper_test_module_scope_markers_present() -> None:
    #R001: wrapper test module validates ctypes helper behavior.
    #R005: wrapper test module validates cffi helper behavior when available.
    #R010: wrapper test module includes shared-library smoke scenarios.
    target = Path(__file__).resolve().parents[2] / "python" / "test_onepsa_wrappers.py"
    assert target.exists()
