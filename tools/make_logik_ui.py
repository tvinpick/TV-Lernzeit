#!/usr/bin/env python3
"""Logik look: recolours the purple Deutsch exercise frame/panels/background to the
Logik orange (hue shift of purple/blue tones only; shading and transparency kept).
   python3 tools/make_logik_ui.py   -> lernzeit/assets/logik/ui/*.png
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "lernzeit", "assets")
SRC = [
    "deutsch/backgrounds/Deutsch_Buchstaben_Background_1080p.png",
    "deutsch/ui/panels/Deutsch_Content_Panel.png",
    "deutsch/ui/panels/Deutsch_Header_Panel.png",
    "deutsch/ui/panels/Deutsch_Question_Panel.png",
    "deutsch/ui/panels/Deutsch_Word_Panel.png",
    "deutsch/ui/panels/Deutsch_Picture_Frame.png",
    "deutsch/ui/progress/Deutsch_Progress_Track.png",
    "deutsch/ui/progress/Deutsch_Progress_Dot_Current.png",
    "deutsch/ui/progress/Deutsch_Progress_Dot_Done.png",
    "deutsch/ui/progress/Deutsch_Progress_Dot_Pending.png",
    "deutsch/ui/controls/Deutsch_Progress_Counter_Blank.png",
    "deutsch/ui/word_tiles/Deutsch_Word_Slot_Blank.png",
    "deutsch/ui/word_tiles/Deutsch_Word_Slot_Filled.png",
    "deutsch/ui/word_tiles/Deutsch_Word_Slot_Selected.png",
]


def recolor(a: np.ndarray) -> np.ndarray:
    rgb = a[..., :3].astype(np.float32) / 255.0
    mx, mn = rgb.max(-1), rgb.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    m = d > 1e-6
    rm = m & (mx == r)
    gm = m & (mx == g) & ~rm
    bm = m & ~rm & ~gm
    h[rm] = ((g - b)[rm] / d[rm]) % 6
    h[gm] = (b - r)[gm] / d[gm] + 2
    h[bm] = (r - g)[bm] / d[bm] + 4
    h *= 60.0
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0)
    v = mx
    # purple / blue / cyan tones -> warm orange family (amber for light, orange for strong tones)
    sel = (h >= 170) & (h <= 335) & (s > 0.04)
    h2 = np.where(sel, 34 - (h - 255) * 0.12, h)
    s2 = np.where(sel, np.minimum(1, s * 1.08), s)
    # back to rgb
    c = v * s2
    hp = (h2 % 360) / 60.0
    x = c * (1 - np.abs(hp % 2 - 1))
    z = np.zeros_like(c)
    conds = [(hp < 1), (hp < 2), (hp < 3), (hp < 4), (hp < 5), (hp >= 5)]
    vals = [(c, x, z), (x, c, z), (z, c, x), (z, x, c), (x, z, c), (c, z, x)]
    out = np.zeros_like(rgb)
    done = np.zeros(c.shape, bool)
    for cond, (rr, gg, bb) in zip(conds, vals):
        k = cond & ~done
        out[..., 0][k], out[..., 1][k], out[..., 2][k] = rr[k], gg[k], bb[k]
        done |= k
    out += (v - c)[..., None]
    res = a.copy()
    res[..., :3] = np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8)
    return res


def main():
    dst = os.path.join(ROOT, "logik", "ui")
    os.makedirs(dst, exist_ok=True)
    for p in SRC:
        im = Image.open(os.path.join(ROOT, p)).convert("RGBA")
        out = Image.fromarray(recolor(np.array(im)), "RGBA")
        name = os.path.basename(p).replace("Deutsch_Buchstaben_", "Logik_").replace("Deutsch_", "Logik_")
        if name.startswith("Logik_Background"):
            out = out.convert("RGB")
        out.save(os.path.join(dst, name), optimize=True)
    print(len(SRC), "files ->", os.path.normpath(dst))


if __name__ == "__main__":
    main()
