"""Offline generator for the sound effect bank.

Writes the .wav files under resources/audio/sfx from the recipes below, so the
bank can be rebuilt without opening the editor:

    python3 tools/make_sfx.py

scripts/systems/audio.gd parses each file's RIFF header directly, which needs no
importer and therefore also works in exported builds. Output is deterministic
(fixed seed), so regenerating never churns the repository.
"""

import math
import os
import random
import struct
import sys
import wave

RATE = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "resources", "audio", "sfx"))

_rng = random.Random(1234)
_noise_state = 0.0


# --- synthesis helpers -------------------------------------------------------


def _blank(seconds: float) -> list:
    return [0.0] * int(seconds * RATE)


def _env(t: float, length: float, attack: float, curve: float) -> float:
    if t <= 0.0:
        return 0.0
    if t < attack:
        return t / max(attack, 0.00001)
    progress = (t - attack) / max(length - attack, 0.00001)
    if progress <= 0.0:
        return 0.0
    return max(1.0 - progress, 0.0) ** curve


def _lerpf(a: float, b: float, w: float) -> float:
    return a + (b - a) * w


def _clampf(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def _square(frequency: float, t: float) -> float:
    return 1.0 if (t * frequency) % 1.0 < 0.5 else -1.0


def _triangle(frequency: float, t: float) -> float:
    phase = (t * frequency) % 1.0
    return 4.0 * abs(phase - 0.5) - 1.0


def _noise() -> float:
    return _rng.uniform(-1.0, 1.0)


def _lowpass(sample: float, amount: float) -> float:
    global _noise_state
    _noise_state += (sample - _noise_state) * amount
    return _noise_state


def _highpass(sample: float, amount: float) -> float:
    return sample - _lowpass(sample, 1.0 - amount)


def _bandpass(sample: float, high: float, low: float) -> float:
    bright = _lowpass(sample, high)
    return bright - bright * low


def _shape(sample: float) -> float:
    return math.tanh(sample * 2.2) * 0.8


def _reset_noise() -> None:
    global _noise_state
    _noise_state = 0.0


# --- sounds ------------------------------------------------------------------


def _chop() -> list:
    _reset_noise()
    length = 0.22
    samples = _blank(length)
    phase = 0.0
    for index in range(len(samples)):
        t = index / RATE
        envelope = _env(t, length, 0.004, 3.0)
        phase += math.tau * _lerpf(210.0, 80.0, t / length) / RATE
        body = math.sin(phase) * 0.5
        grain = _lowpass(_noise(), 0.35) * 0.9
        samples[index] = (body + grain) * envelope * 0.7
    return samples


def _mine() -> list:
    _reset_noise()
    length = 0.2
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        click = _highpass(_noise(), 0.6) * _env(t, 0.05, 0.001, 4.0)
        ring = (
            math.sin(math.tau * 1280.0 * t) * 0.35
            + math.sin(math.tau * 1830.0 * t) * 0.2
        ) * _env(t, length, 0.001, 5.0)
        samples[index] = (click * 0.8 + ring) * 0.65
    return samples


def _till() -> list:
    _reset_noise()
    length = 0.28
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        shape = math.sin(math.pi * _clampf(t / length, 0.0, 1.0))
        samples[index] = _bandpass(_noise(), 0.5, 0.12) * shape * 0.75
    return samples


def _water() -> list:
    _reset_noise()
    length = 0.6
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        shape = math.sin(math.pi * _clampf(t / length, 0.0, 1.0))
        wobble = 0.82 + 0.18 * math.sin(math.tau * 7.0 * t)
        samples[index] = _lowpass(_noise(), 0.22) * shape * wobble * 0.85
    return samples


def _plant() -> list:
    _reset_noise()
    length = 0.13
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        envelope = _env(t, length, 0.008, 3.5)
        samples[index] = (
            _triangle(430.0, t) * 0.6 + _lowpass(_noise(), 0.2) * 0.4
        ) * envelope * 0.5
    return samples


def _pickup() -> list:
    _reset_noise()
    length = 0.15
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        frequency = 720.0 if t < length * 0.45 else 1080.0
        samples[index] = _square(frequency, t) * _env(t, length, 0.003, 1.6) * 0.28
    return samples


def _harvest() -> list:
    _reset_noise()
    length = 0.34
    notes = [523.25, 659.25, 830.61]
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        step = min(int(t / (length / len(notes))), len(notes) - 1)
        samples[index] = _triangle(notes[step], t) * _env(t, length, 0.004, 1.2) * 0.34
    return samples


def _ui_click() -> list:
    _reset_noise()
    length = 0.055
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        samples[index] = _square(940.0, t) * _env(t, length, 0.002, 2.0) * 0.2
    return samples


def _ui_move() -> list:
    _reset_noise()
    length = 0.04
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        samples[index] = _square(520.0, t) * _env(t, length, 0.002, 2.0) * 0.15
    return samples


def _deny() -> list:
    _reset_noise()
    length = 0.16
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        samples[index] = _square(150.0, t) * _env(t, length, 0.004, 1.4) * 0.22
    return samples


def _chest_open() -> list:
    _reset_noise()
    length = 0.4
    samples = _blank(length)
    phase = 0.0
    for index in range(len(samples)):
        t = index / RATE
        knock = _lowpass(_noise(), 0.3) * _env(t, 0.06, 0.002, 3.0) * 0.8
        phase += math.tau * _lerpf(320.0, 610.0, _clampf(t / length, 0.0, 1.0)) / RATE
        creak = math.sin(phase) * 0.22 * math.sin(math.pi * _clampf(t / length, 0.0, 1.0))
        samples[index] = (knock + creak) * 0.6
    return samples


def _cluck() -> list:
    _reset_noise()
    length = 0.26
    samples = _blank(length)
    phase = 0.0
    for index in range(len(samples)):
        t = index / RATE
        gate = 1.0 if (t < 0.07 or (0.12 < t < 0.2)) else 0.0
        warble = 1.0 + 0.28 * math.sin(math.tau * 34.0 * t)
        phase += math.tau * 870.0 * warble / RATE
        samples[index] = (
            _shape(math.sin(phase)) * gate * _env(t, length, 0.004, 0.6) * 0.24
        )
    return samples


def _moo() -> list:
    _reset_noise()
    length = 0.85
    samples = _blank(length)
    phase = 0.0
    for index in range(len(samples)):
        t = index / RATE
        progress = _clampf(t / length, 0.0, 1.0)
        vibrato = 1.0 + 0.05 * math.sin(math.tau * 5.5 * t)
        phase += math.tau * _lerpf(196.0, 128.0, progress) * vibrato / RATE
        body = (
            math.sin(phase) * 0.6
            + math.sin(phase * 2.0) * 0.22
            + math.sin(phase * 3.0) * 0.1
        )
        samples[index] = body * math.sin(math.pi * progress ** 0.7) * 0.36
    return samples


def _sleep() -> list:
    _reset_noise()
    length = 1.1
    samples = _blank(length)
    phase = 0.0
    for index in range(len(samples)):
        t = index / RATE
        progress = _clampf(t / length, 0.0, 1.0)
        phase += math.tau * _lerpf(392.0, 196.0, progress) / RATE
        samples[index] = (
            (math.sin(phase) * 0.6 + math.sin(phase * 0.5) * 0.3)
            * _env(t, length, 0.08, 1.4)
            * 0.3
        )
    return samples


def _step() -> list:
    _reset_noise()
    length = 0.06
    samples = _blank(length)
    for index in range(len(samples)):
        t = index / RATE
        samples[index] = _lowpass(_noise(), 0.25) * _env(t, length, 0.002, 3.0) * 0.22
    return samples


# --- output ------------------------------------------------------------------


SOUNDS = [
    ("chop", _chop),
    ("mine", _mine),
    ("till", _till),
    ("water", _water),
    ("plant", _plant),
    ("pickup", _pickup),
    ("harvest", _harvest),
    ("ui_click", _ui_click),
    ("ui_move", _ui_move),
    ("deny", _deny),
    ("chest_open", _chest_open),
    ("cluck", _cluck),
    ("moo", _moo),
    ("sleep", _sleep),
    ("step", _step),
]


def _write_wav(name: str, samples: list) -> None:
    path = os.path.join(OUT, "%s.wav" % name)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        payload = b"".join(
            struct.pack("<h", int(_clampf(s, -1.0, 1.0) * 32767.0)) for s in samples
        )
        handle.writeframes(payload)
    print("%-12s %5.2fs  %s" % (name, len(samples) / RATE, path))


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    for name, recipe in SOUNDS:
        _write_wav(name, recipe())
    return 0


if __name__ == "__main__":
    sys.exit(main())
