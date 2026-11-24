"""ctypes interface to the shared LegoBlast simulation and asset decoder."""

import ctypes as ct
from pathlib import Path
import sys


class State(ct.Structure):
    _fields_ = [(name, ct.c_uint32) for name in (
        "mode phase arena round elapsed players bombs track revision musicMs musicVolume effectsVolume "
        "voices flags networkEnabled connected seat sharedKeyboard mainPage"
    ).split()] + [(name, ct.c_char * length) for name, length in (
        ("room", 8), ("roster", 8), ("offer", 8), ("notice", 64), ("message", 64),
    )]


def find_library():
    if hasattr(sys, "_MEIPASS"):
        base = Path(sys._MEIPASS)
    else:
        base = Path(__file__).resolve().parent
    name = {"win32": "legoblast_python.dll", "darwin": "liblegoblast_python.dylib"}.get(
        sys.platform, "liblegoblast_python.so")
    return base / name


class Engine:
    def __init__(self, library, data, settings, endpoint):
        self.lib = ct.CDLL(str(library.resolve()))
        settings.mkdir(parents=True, exist_ok=True)
        handle, string, integer, uint = ct.c_void_p, ct.c_char_p, ct.c_int, ct.c_uint
        byte_pointer = ct.POINTER(ct.c_uint8)
        api = {
            "abi": (uint, []), "controls": (uint, []), "error": (string, []),
            "open": (handle, [string, string, string]), "close": (None, [handle]),
            "save": (integer, [handle]), "start": (integer, [handle, uint]),
            "menu": (integer, [handle, uint]), "voices": (None, [handle, uint]),
            "poll": (integer, [handle, ct.c_uint64]), "tick": (integer, [handle, byte_pointer, uint]),
            "command": (integer, [handle, string]), "network": (integer, [handle, string]),
            "volume": (None, [handle, integer, integer]),
            "sounds": (uint, [handle, ct.POINTER(integer), uint]),
            "state": (None, [handle, ct.POINTER(State)]),
            "picture": (byte_pointer, [handle, uint, uint, ct.POINTER(integer), ct.POINTER(integer)]),
        }
        for name, (result, args) in api.items():
            function = getattr(self.lib, "lb_" + name)
            function.restype = result
            function.argtypes = args
        if self.lib.lb_abi() != 1 or self.lib.lb_controls() < 8:
            raise RuntimeError("Bibliothèque LegoBlast incompatible")
        self.inputs = (ct.c_uint8 * self.lib.lb_controls())()
        self.handle = self.lib.lb_open(str(data.resolve()).encode(), str(settings.resolve()).encode(),
                                      endpoint.encode())
        if not self.handle:
            self.fail()

    def fail(self):
        raise RuntimeError(self.lib.lb_error().decode(errors="replace"))

    def call(self, name, *args):
        result = getattr(self.lib, "lb_" + name)(self.handle, *args)
        if isinstance(result, int) and result < 0:
            self.fail()
        return result

    def close(self):
        if self.handle:
            try:
                self.call("save")
            finally:
                self.call("close")
                self.handle = None

    def state(self):
        snapshot = State()
        self.call("state", ct.byref(snapshot))
        return snapshot

    def tick(self, controls, summons=0):
        for index in range(len(self.inputs)):
            self.inputs[index] = controls[index] if index < len(controls) else 0
        self.call("tick", self.inputs, summons)

    def frame(self, mode=0, tick=0):
        w, h = ct.c_int(), ct.c_int()
        pixels = self.call("picture", mode, tick, ct.byref(w), ct.byref(h))
        if not pixels:
            self.fail()
        return ct.string_at(pixels, w.value * h.value * 3), (w.value, h.value)

    def sounds(self):
        output = (ct.c_int * 96)()
        size = self.call("sounds", output, 32)
        return [tuple(output[index:index + 3]) for index in range(0, size * 3, 3)]
