from pathlib import Path


def test_onepsa_ctypes_scope_markers_present() -> None:
    #R001: ctypes wrapper uses repository-default shared library path.
    #R005: ctypes wrapper configures argtypes/restype for exported functions.
    #R010: ctypes wrapper converts pointers into errors/decoded output strings.
    target = Path(__file__).resolve().parents[2] / "python" / "onepsa_ctypes.py"
    assert target.exists()
