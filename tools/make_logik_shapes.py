#!/usr/bin/env python3
"""Draws the Logik shapes (7 shapes x 4 colours) in the style of the Logik kit:
flat colour, darker lower half, glossy highlight, thick dark-teal outline, transparent.
   python3 tools/make_logik_shapes.py   -> lernzeit/assets/logik/shapes/Shape_<Form>_<Farbe>.png
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "lernzeit", "assets", "logik", "shapes")
S = 1024            # drawn large, saved at 256
OUTLINE = (17, 78, 76, 255)
COLORS = {
    "Rot": ((250, 98, 92), (226, 64, 64)),
    "Blau": ((72, 182, 246), (38, 140, 220)),
    "Gelb": ((255, 221, 64), (246, 184, 22)),
    "Gruen": ((112, 212, 96), (64, 170, 70)),
}


def poly_star(cx, cy, r1, r2, n=5):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = -math.pi / 2 + i * math.pi / n
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def heart(cx, cy, r):
    pts = []
    for i in range(200):
        t = 2 * math.pi * i / 200
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * r / 17, cy - y * r / 17 + r * 0.08))
    return pts


def mask_for(shape):
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    c, r = S / 2, S * 0.40
    if shape == "Kreis":
        d.ellipse([c - r, c - r, c + r, c + r], fill=255)
    elif shape == "Quadrat":
        d.rounded_rectangle([c - r * 0.92, c - r * 0.92, c + r * 0.92, c + r * 0.92], radius=60, fill=255)
    elif shape == "Rechteck":
        d.rounded_rectangle([c - r * 1.0, c - r * 0.6, c + r * 1.0, c + r * 0.6], radius=55, fill=255)
    elif shape == "Dreieck":
        d.polygon([(c, c - r * 0.95), (c + r * 0.98, c + r * 0.8), (c - r * 0.98, c + r * 0.8)], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(14)).point(lambda v: 255 if v > 128 else 0)
    elif shape == "Stern":
        d.polygon(poly_star(c, c + r * 0.08, r * 1.0, r * 0.44), fill=255)
        m = m.filter(ImageFilter.GaussianBlur(12)).point(lambda v: 255 if v > 128 else 0)
    elif shape == "Herz":
        d.polygon(heart(c, c - r * 0.12, r * 0.98), fill=255)
    elif shape == "Raute":
        d.polygon([(c, c - r * 1.1), (c + r * 0.85, c), (c, c + r * 1.1), (c - r * 0.85, c)], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(12)).point(lambda v: 255 if v > 128 else 0)
    return m


def render(shape, light, dark):
    m = mask_for(shape)
    bbox = m.getbbox()
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # outline: dilated mask
    outline = m.filter(ImageFilter.MaxFilter(45))
    img.paste(Image.new("RGBA", (S, S), OUTLINE), (0, 0), outline)
    # body: vertical gradient light -> dark
    grad = Image.new("RGBA", (S, S))
    gd = ImageDraw.Draw(grad)
    top, bottom = bbox[1], bbox[3]
    for y in range(S):
        t = min(1, max(0, (y - top) / max(1, bottom - top)))
        t = max(0, (t - 0.45) / 0.55)
        col = tuple(int(light[i] + (dark[i] - light[i]) * t) for i in range(3)) + (255,)
        gd.line([(0, y), (S, y)], fill=col)
    img.paste(grad, (0, 0), m)
    # glossy highlight in the upper-left part
    hl = Image.new("L", (S, S), 0)
    hd = ImageDraw.Draw(hl)
    x0, y0 = bbox[0] + (bbox[2] - bbox[0]) * 0.18, bbox[1] + (bbox[3] - bbox[1]) * 0.12
    hd.ellipse([x0, y0, x0 + (bbox[2] - bbox[0]) * 0.32, y0 + (bbox[3] - bbox[1]) * 0.13], fill=150)
    hl = Image.composite(hl, Image.new("L", (S, S), 0), m.filter(ImageFilter.MinFilter(41)))
    img.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), hl.filter(ImageFilter.GaussianBlur(6)))
    return img.resize((256, 256), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for shape in ["Kreis", "Quadrat", "Rechteck", "Dreieck", "Stern", "Herz", "Raute"]:
        for name, (light, dark) in COLORS.items():
            render(shape, light, dark).save(os.path.join(OUT, f"Shape_{shape}_{name}.png"), optimize=True)
            n += 1
    print(n, "shapes ->", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
