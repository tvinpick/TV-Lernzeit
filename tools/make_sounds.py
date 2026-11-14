#!/usr/bin/env python3
"""Generates the short UI sounds (own synthesis, no third-party audio).
Usage: python3 tools/make_sounds.py lernzeit/assets/sounds"""
import os, sys, wave, numpy as np
SR = 44100
out = sys.argv[1]; os.makedirs(out, exist_ok=True)

def env(n, a=0.004, r=0.6):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / a) * np.exp(-t / (r * n / SR))
    return e

def tone(freqs, dur, vol=0.35, r=0.35):
    n = int(SR * dur); t = np.arange(n) / SR
    sig = sum(np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t) for f in freqs) / len(freqs)
    return sig * env(n, r=r) * vol

def seq(*parts):
    return np.concatenate(parts)

def write(name, sig):
    sig = np.clip(sig, -1, 1)
    with wave.open(os.path.join(out, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((sig * 32767).astype(np.int16).tobytes())

write("move.wav", tone([1318.5], 0.045, 0.18, 0.3))
write("select.wav", seq(tone([880.0], 0.06, 0.3), tone([1318.5], 0.11, 0.3)))
write("back.wav", seq(tone([987.8], 0.05, 0.25), tone([659.3], 0.09, 0.25)))
write("toggle.wav", tone([1046.5, 1568.0], 0.07, 0.25, 0.3))
write("error.wav", seq(tone([311.1], 0.09, 0.3), tone([277.2], 0.14, 0.3)))
# streak: rising arpeggio; pop: short bright blip (star arrives in the progress bar)
write("streak.wav", seq(tone([784.0], 0.07, 0.28), tone([987.8], 0.07, 0.28), tone([1174.7], 0.07, 0.28), tone([1568.0, 1975.5], 0.22, 0.3)))
write("pop.wav", tone([1760.0, 2637.0], 0.06, 0.2, 0.25))
write("pause.wav", seq(tone([659.3], 0.12, 0.25), tone([523.3], 0.12, 0.25), tone([392.0, 523.3], 0.3, 0.25)))
print("sounds written to", out)
