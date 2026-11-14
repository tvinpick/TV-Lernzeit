#!/usr/bin/env python3
"""Balloon colours for the reward game: hue-shifted copies of Balloon_Red.png.
   python3 tools/make_balloons.py   -> lernzeit/assets/game/Balloon_<Farbe>.png
"""
import os
import numpy as np
from PIL import Image

A = os.path.join(os.path.dirname(__file__), "..", "lernzeit", "assets")
SHIFT = {"Rot": 0, "Orange": 28, "Gelb": 50, "Gruen": 120, "Blau": 210, "Lila": 280}


def shift(img: Image.Image, deg: float) -> Image.Image:
    hsv = np.array(img.convert("RGB").convert("HSV")).astype(np.int32)
    sat_mask = hsv[..., 1] > 40                    # keep the white shine and the dark string
    hsv[..., 0] = np.where(sat_mask, (hsv[..., 0] + int(deg / 360 * 255)) % 256, hsv[..., 0])
    out = Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB")
    out.putalpha(img.getchannel("A"))
    return out


def main():
    src = Image.open(os.path.join(A, "math", "shared_ui", "Balloon_Red.png")).convert("RGBA")
    dst = os.path.join(A, "game")
    os.makedirs(dst, exist_ok=True)
    for name, deg in SHIFT.items():
        shift(src, deg).save(os.path.join(dst, f"Balloon_{name}.png"), optimize=True)
    print(len(SHIFT), "balloons ->", os.path.normpath(dst))


if __name__ == "__main__":
    main()
