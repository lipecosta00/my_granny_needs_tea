"""Synthesizes the placeholder SFX (jsfxr-style) as 16-bit mono WAV.

Run: python3 tools/audio/gen_sfx.py
Deterministic (fixed seed), stdlib only. Replace with jsfxr exports later
(GDD "Áudio"); keep the same file names so nothing else changes.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[2] / "assets" / "sfx"


def env(t, dur, attack=0.005):
    """Linear attack, exponential-ish decay."""
    if t < attack:
        return t / attack
    return max(0.0, 1.0 - (t - attack) / (dur - attack)) ** 2


def square(phase):
    return 1.0 if (phase % 1.0) < 0.5 else -1.0


def render(dur, fn, gain=0.5):
    rng = random.Random(42)
    samples, phase, lp = [], 0.0, 0.0
    n = int(dur * RATE)
    for i in range(n):
        t = i / RATE
        value, phase, lp = fn(t, dur, phase, lp, rng)
        samples.append(max(-1.0, min(1.0, value * gain)))
    return samples


def tone_sweep(f0, f1, noise=0.0, wave_fn=square, lowpass=1.0):
    def fn(t, dur, phase, lp, rng):
        freq = f0 + (f1 - f0) * (t / dur)
        phase += freq / RATE
        raw = wave_fn(phase) * (1 - noise) + rng.uniform(-1, 1) * noise
        lp += (raw - lp) * lowpass
        return lp * env(t, dur), phase, lp
    return fn


def whoosh(cut0, cut1):
    def fn(t, dur, phase, lp, rng):
        cutoff = cut0 + (cut1 - cut0) * (t / dur)
        lp += (rng.uniform(-1, 1) - lp) * cutoff
        shaped = math.sin(math.pi * min(1.0, t / dur))  # swell in and out
        return lp * shaped * 2.5, phase, lp
    return fn


def blips(freqs, each):
    def fn(t, dur, phase, lp, rng):
        idx = min(int(t / each), len(freqs) - 1)
        local = t - idx * each
        phase += freqs[idx] / RATE
        return math.sin(phase * math.tau) * env(local, each, 0.002), phase, lp
    return fn


SOUNDS = {
    "swing": (0.14, whoosh(0.45, 0.08), 0.55),
    "hit": (0.10, tone_sweep(320, 70, noise=0.35, lowpass=0.6), 0.5),
    "hit_heavy": (0.22, tone_sweep(180, 40, noise=0.5, lowpass=0.5), 0.65),
    "roll": (0.20, whoosh(0.15, 0.04), 0.45),
    "hurt": (0.20, tone_sweep(520, 160, noise=0.1), 0.4),
    "enemy_die": (0.30, tone_sweep(260, 40, noise=0.6, lowpass=0.4), 0.55),
    "charge_ready": (0.16, blips([880, 1320], 0.08), 0.35),
    "spider_warn": (0.12, tone_sweep(500, 900, noise=0.05), 0.25),
    "spark": (0.07, tone_sweep(1400, 2200, wave_fn=lambda p: math.sin(p * math.tau)), 0.25),
    "flash": (0.35, blips([660, 880, 1320, 1760], 0.07), 0.4),
    "gate_open": (0.6, blips([392, 523, 659, 784, 1047], 0.11), 0.35),
    "pet_out": (0.4, tone_sweep(600, 150, wave_fn=lambda p: math.sin(p * math.tau)), 0.35),
    "fizzle": (0.12, tone_sweep(160, 110, noise=0.3, lowpass=0.3), 0.3),
}


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))


if __name__ == "__main__":
    for sound_name, (duration, generator, gain) in SOUNDS.items():
        write(sound_name, render(duration, generator, gain))
        print("wrote", OUT / f"{sound_name}.wav")
