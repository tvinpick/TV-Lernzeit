#!/usr/bin/env python3
"""New achievement medals in the style of the mascot badges: the gold rosette of
Badge_first_steps.png with a new inner disc (colour gradient + emblem from the
app's own icons / owl, optionally a number).
   python3 tools/make_badges.py   -> lernzeit/assets/mascot/badges/Badge_<id>.png
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

A = os.path.join(os.path.dirname(__file__), "..", "lernzeit", "assets")
FONT = os.path.join(A, "fonts", "Nunito_800ExtraBold.ttf")
CX, CY, R = 197, 177, 113          # inner disc of the 400 px rosette

SKY = {"blue": ((120, 200, 255), (40, 120, 230)), "green": ((150, 230, 140), (50, 160, 80)),
       "orange": ((255, 210, 120), (240, 130, 40)), "purple": ((215, 170, 255), (140, 80, 220)),
       "pink": ((255, 180, 210), (230, 90, 150)), "teal": ((140, 235, 220), (30, 160, 160))}

# id: (emblem png relative to assets, sky, number text or "")
BADGES = {
    "level_5": ("math/shared_ui/Object_Star_Yellow.png", "blue", "5"),
    "level_10": ("math/shared_ui/Object_Star_Yellow.png", "purple", "10"),
    "level_20": ("math/shared_ui/Object_Star_Yellow.png", "pink", "20"),
    "tasks_500": ("icons/Lernzeit_Icon_Tasks.png", "teal", "500"),
    "sessions_50": ("icons/Lernzeit_Icon_Progress.png", "blue", "50"),
    "perfect_10": ("icons/Lernzeit_Icon_Correct.png", "green", "10"),
    "all_subjects": ("icons/Lernzeit_Icon_Subjects.png", "orange", ""),
    "logik_3": ("icons/subject_logik.png", "orange", ""),
    "lesen_3": ("icons/subject_lesen.png", "green", ""),
    "goal_3": ("icons/Lernzeit_Icon_Target.png", "pink", ""),
    "letters_all": ("icons/subject_deutsch.png", "purple", ""),
    "test_1": ("mascot/owl/Mascot_Owl_Thinking.png", "teal", ""),
    "test_green": ("mascot/owl/Mascot_Owl_Cheer.png", "green", ""),
}


def make(emblem: str, sky: str, number: str) -> Image.Image:
    base = Image.open(os.path.join(A, "mascot", "badges", "Badge_first_steps.png")).convert("RGBA")
    orig = np.array(base)
    img = base.copy()
    # gradient disc
    top, bottom = SKY[sky]
    disc = Image.new("RGBA", img.size, (0, 0, 0, 0))
    g = ImageDraw.Draw(disc)
    for y in range(CY - R, CY + R + 1):
        t = (y - (CY - R)) / (2 * R)
        col = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        g.line([(CX - R, y), (CX + R, y)], fill=col)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse([CX - R, CY - R, CX + R, CY + R], fill=255)
    # soft sun rays
    rays = Image.new("L", img.size, 0)
    rd = ImageDraw.Draw(rays)
    import math
    for k in range(12):
        a0 = k * math.pi / 6
        rd.polygon([(CX, CY), (CX + 200 * math.cos(a0 - 0.12), CY + 200 * math.sin(a0 - 0.12)),
                    (CX + 200 * math.cos(a0 + 0.12), CY + 200 * math.sin(a0 + 0.12))], fill=40)
    disc.paste(Image.new("RGBA", img.size, (255, 255, 255, 255)), (0, 0), rays)
    img.paste(disc, (0, 0), mask)
    # emblem
    em = Image.open(os.path.join(A, emblem)).convert("RGBA")
    em = em.crop(em.getbbox())
    box = 150 if number == "" else 104
    s = box / max(em.size)
    em = em.resize((max(1, int(em.width * s)), max(1, int(em.height * s))), Image.LANCZOS)
    shadow = Image.new("RGBA", em.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", em.size, (20, 40, 90, 110)), (0, 0), em.split()[3])
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    ex, ey = CX - em.width // 2, CY - em.height // 2 - (34 if number else 0)
    img.alpha_composite(shadow, (ex + 4, ey + 6))
    img.alpha_composite(em, (ex, ey))
    if number:
        f = ImageFont.truetype(FONT, 60 if len(number) < 3 else 50)
        d = ImageDraw.Draw(img)
        tw = d.textlength(number, font=f)
        d.text((CX - tw / 2, CY + 14), number, font=f, fill=(255, 255, 255, 255),
               stroke_width=7, stroke_fill=(30, 60, 140, 255))
    # keep the gold star / ribbon that overlaps the lower disc edge
    arr = np.array(img)
    o = orig
    gold = (o[..., 0] > 190) & (o[..., 1] > 120) & (o[..., 2] < 140) & (o[..., 3] > 200)
    yy = np.arange(o.shape[0])[:, None] * np.ones((1, o.shape[1]), int)
    keep = gold & (yy > CY + R - 22)
    arr[keep] = o[keep]
    return Image.fromarray(arr, "RGBA")


def main():
    out = os.path.join(A, "mascot", "badges")
    for bid, (emblem, sky, number) in BADGES.items():
        make(emblem, sky, number).save(os.path.join(out, f"Badge_{bid}.png"), optimize=True)
    print(len(BADGES), "badges ->", os.path.normpath(out))


if __name__ == "__main__":
    main()
