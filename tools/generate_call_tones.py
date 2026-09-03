"""Generates the two call tones as 16-bit mono WAV.

Synthesised rather than shipped as a downloaded file: a real ringtone is
somebody's copyright, and a tone the app generates from a description can be
read and changed by the next person who wants it a semitone lower.
"""
import math
import struct
import wave
import sys

RATE = 44100


def envelope(i, n, attack=0.012, release=0.09):
    """Soft edges. A raw sine switched on at full amplitude clicks."""
    t = i / RATE
    total = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (total - t) / release) if release > 0 else 1.0
    return max(0.0, a * r)


def tone(freqs, seconds, gain=0.32):
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        v = 0.0
        for f, w in freqs:
            v += w * math.sin(2 * math.pi * f * t)
        out.append(v * gain * envelope(i, n))
    return out


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def write(path, samples):
    with wave.open(path, 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        frames = b''.join(
            struct.pack('<h', max(-32768, min(32767, int(s * 32767))))
            for s in samples
        )
        f.writeframes(frames)


# ─── Incoming: a rising three-note motif, twice, then a rest ───────────────
#
# A5, C#6, E6 — an A-major arpeggio, which is bright enough to carry from a
# pocket without being shrill. Each note carries a quiet octave above it so it
# reads as a chime rather than a test tone.
def note(f, seconds):
    return tone([(f, 1.0), (f * 2, 0.22)], seconds)


motif = note(880.00, 0.16) + note(1108.73, 0.16) + note(1318.51, 0.30)
ring = motif + silence(0.10) + motif + silence(1.60)
write(sys.argv[1], ring)

# ─── Outgoing: the classic ringback, so the caller hears it connecting ─────
#
# 440 + 480 Hz for a second, then a rest. Deliberately duller than the
# incoming tone: the caller is holding the phone and does not need to be
# summoned by it.
ringback = tone([(440.0, 0.55), (480.0, 0.55)], 1.0, gain=0.22) + silence(2.4)
write(sys.argv[2], ringback)
print('written')
