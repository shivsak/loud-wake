#!/usr/bin/env python3
"""Generate loud, loopable alarm tones for LoudWake.

Outputs 16-bit / 44.1kHz mono WAV files into Sources/Resources/Sounds.
Run `make_sounds.sh` afterwards to also produce .caf versions via afconvert.

These are intentionally harsh and near-full-amplitude. They are designed to wake a
heavy sleeper, not to sound pleasant.
"""
import math
import os
import struct
import wave

SAMPLE_RATE = 44100
AMP = 0.92  # leave a little headroom to avoid hard clipping
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "Sources", "Resources", "Sounds")


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            s = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(s * 32767))
        w.writeframes(bytes(frames))
    print("wrote", path, f"({len(samples)/SAMPLE_RATE:.2f}s)")


def square_ish(phase, harshness=0.45):
    """A sine blended with its odd harmonics for a buzzier, louder-perceived tone."""
    s = math.sin(phase)
    s += harshness * math.sin(3 * phase) / 3
    s += harshness * math.sin(5 * phase) / 5
    return s / (1 + harshness * (1 / 3 + 1 / 5))


def siren_loud(duration=4.0):
    """Continuous siren sweeping 600<->1200 Hz, loops seamlessly."""
    n = int(SAMPLE_RATE * duration)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        # full sweep cycle per second of file so the loop boundary lines up
        sweep = 0.5 - 0.5 * math.cos(2 * math.pi * (t / duration) * 4)
        freq = 600 + 600 * sweep
        phase += 2 * math.pi * freq / SAMPLE_RATE
        out.append(AMP * square_ish(phase, 0.5))
    return out


def klaxon(duration=4.0):
    """Alternating two-tone honk (like an alarm horn)."""
    n = int(SAMPLE_RATE * duration)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        slot = int(t * 4) % 2  # switch tone 4x/sec
        freq = 480 if slot == 0 else 660
        phase += 2 * math.pi * freq / SAMPLE_RATE
        # hard gate edges for a punchy honk
        gate = 1.0 if (t * 8) % 1.0 < 0.92 else 0.0
        out.append(AMP * square_ish(phase, 0.6) * gate)
    return out


def rising_beep(duration=4.0):
    """Accelerating beeps that climb in pitch — escalating urgency."""
    n = int(SAMPLE_RATE * duration)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        cycle = t % 1.0
        beep_freq = 700 + 500 * cycle
        phase += 2 * math.pi * beep_freq / SAMPLE_RATE
        # 6 short beeps per second with sharp envelope
        sub = (t * 6) % 1.0
        env = 1.0 if sub < 0.55 else 0.0
        out.append(AMP * square_ish(phase, 0.4) * env)
    return out


def keepalive(duration=1.0):
    """A near-silent low tone. Played on loop to keep the app alive in the background so
    it can take over and ring on its own. Inaudible in practice."""
    n = int(SAMPLE_RATE * duration)
    out = []
    phase = 0.0
    for i in range(n):
        phase += 2 * math.pi * 40 / SAMPLE_RATE  # 40 Hz
        out.append(0.0008 * math.sin(phase))
    return out


if __name__ == "__main__":
    write_wav("siren_loud", siren_loud())
    write_wav("klaxon", klaxon())
    write_wav("rising_beep", rising_beep())
    write_wav("keepalive", keepalive())
