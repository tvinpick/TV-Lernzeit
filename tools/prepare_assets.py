#!/usr/bin/env python3
"""Lernzeit asset preparation.

Reads the original design pack (Lernzeit_Assets_For_Claude_v0_1.zip, extracted)
and writes the runtime textures into lernzeit/assets/.

What it does (see ASSETS_USED.md):
  * removes German text that is baked into PNGs (subject cards, home buttons,
    main background subtitle) by per-row / per-column colour interpolation,
    so that DE/RU labels can be rendered by Godot;
  * builds text-free "pill" button skins by mirroring the clean right cap
    of an original button (used as NinePatch textures);
  * downsizes oversized sprites to at most ~2x their on-screen size at 1080p.

Usage: python3 tools/prepare_assets.py <extracted_zip_dir> <godot_project_dir>
"""
import os, sys, shutil
import numpy as np
from PIL import Image

SRC = os.path.join(sys.argv[1], "assets")
DST = os.path.join(sys.argv[2], "assets")


def load(rel):
    return np.asarray(Image.open(os.path.join(SRC, rel)).convert("RGBA")).astype(np.float32)


def save(arr, rel, max_w=None, max_h=None):
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    w, h = im.size
    s = 1.0
    if max_w and w > max_w:
        s = min(s, max_w / w)
    if max_h and h > max_h:
        s = min(s, max_h / h)
    if s < 1.0:
        im = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    path = os.path.join(DST, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, optimize=True)
    return im.size


def erase_rows(a, x0, x1, y0, y1, feather=12):
    """Replace a[y0:y1, x0:x1] by a per-row linear interpolation between
    column x0-1 and x1 (both must be clean background)."""
    a = a.copy()
    left = a[y0:y1, x0 - 1:x0, :]
    right = a[y0:y1, x1:x1 + 1, :]
    t = np.linspace(0.0, 1.0, x1 - x0)[None, :, None]
    fill = left * (1 - t) + right * t
    # feather top/bottom so the patch blends with untouched rows
    wgt = np.ones((y1 - y0, 1, 1), np.float32)
    f = min(feather, (y1 - y0) // 4)
    if f > 0:
        ramp = np.linspace(0, 1, f)[:, None, None]
        wgt[:f] = ramp
        wgt[-f:] = ramp[::-1]
    a[y0:y1, x0:x1, :] = a[y0:y1, x0:x1, :] * (1 - wgt) + fill * wgt
    return a


def erase_cols(a, x0, x1, y0, y1, feather=40):
    """Per-column vertical interpolation between row y0-1 and y1."""
    a = a.copy()
    top = a[y0 - 1:y0, x0:x1, :]
    bot = a[y1:y1 + 1, x0:x1, :]
    t = np.linspace(0.0, 1.0, y1 - y0)[:, None, None]
    fill = top * (1 - t) + bot * t
    wgt = np.ones((1, x1 - x0, 1), np.float32)
    ramp = np.linspace(0, 1, feather)[None, :, None]
    wgt[:, :feather] = ramp
    wgt[:, -feather:] = ramp[:, ::-1]
    a[y0:y1, x0:x1, :] = a[y0:y1, x0:x1, :] * (1 - wgt) + fill * wgt
    return a


def _longest_run(mask):
    best, cur, start, bs = 0, 0, 0, 0
    for i, v in enumerate(mask):
        if v:
            if cur == 0:
                start = i
            cur += 1
            if cur > best:
                best, bs = cur, start
        else:
            cur = 0
    return bs, bs + best


def trim_to_main_body(a, pad_ratio=0.04):
    """Crop to the largest contiguous block of non-empty rows/columns.
    Drops stray slivers of neighbouring sprites left over from atlas crops."""
    alpha = a[:, :, 3] > 12
    y0, y1 = _longest_run(alpha.sum(1) > 0)
    a = a[y0:y1]
    alpha = alpha[y0:y1]
    x0, x1 = _longest_run(alpha.sum(0) > 0)
    a = a[:, x0:x1]
    pad = int(pad_ratio * max(a.shape[:2]))
    out = np.zeros((a.shape[0] + 2 * pad, a.shape[1] + 2 * pad, 4), np.float32)
    out[pad:pad + a.shape[0], pad:pad + a.shape[1]] = a
    return out


def mirror_pill(a, xr, center=8):
    """Text-free pill: clean right cap a[:, xr:] + its mirror as left cap."""
    r = a[:, xr:, :]
    col = a[:, xr:xr + 1, :].repeat(center, axis=1)
    return np.concatenate([r[:, ::-1, :], col, r], axis=1), r.shape[1]


def main():
    report = []
    os.makedirs(DST, exist_ok=True)

    # ---------- backgrounds ----------
    bg = load("home/Lernzeit_Main_Background_4K.png")
    # subtitle "Was möchtest du heute üben?" sits at ~y 352-460, x 1160-2680
    bg = erase_cols(bg, 1080, 2760, 330, 490, feather=60)
    save(bg[:, :, :], "backgrounds/main_background_4k.png")
    report.append("main background: subtitle removed (rendered by Godot as home_prompt)")
    shutil.copy(os.path.join(SRC, "progress/Lernzeit_Progress_Background_4K_New.png"),
                os.path.join(DST, "backgrounds/progress_background_4k.png"))

    # ---------- subject cards: keep artwork + divider, erase text ----------
    cards = {
        # name: (x0, x1, y0, y1) region of baked text incl. feather margin (source px)
        "Mathematik": (750, 1655, 115, 535),
        "Deutsch": (800, 1650, 125, 545),
        "Lesen": (905, 1645, 115, 505),
        "Logik": (800, 1650, 125, 535),
    }
    for name, (x0, x1, y0, y1) in cards.items():
        a = load(f"home/Lernzeit_Button_{name}.png")
        a = erase_rows(a, x0, x1, y0, y1, feather=30)
        size = save(a, f"buttons/card_{name.lower()}.png", max_w=1200)
        report.append(f"card_{name.lower()}: text removed, {size}")

    # ---------- home buttons: keep icon, erase label ----------
    home = {
        "btn_progress_icon": ("home/Lernzeit_Button_Progress.png", (262, 885, 60, 185)),
        "btn_continue_icon": ("home/Lernzeit_Button_Continue.png", (275, 830, 55, 190)),
        "control_hint_icon": ("home/Lernzeit_Control_Hint.png", (300, 875, 50, 175)),
    }
    for name, (rel, r) in home.items():
        save(erase_rows(load(rel), *r, feather=20), f"buttons/{name}.png", max_w=700)
        report.append(f"{name}: label removed from {os.path.basename(rel)}, icon kept")
    save(load("home/Lernzeit_Button_Settings.png"), "buttons/btn_settings_gear.png", max_w=240)

    # ---------- generic text-free pill skins (StyleBoxTexture / NinePatch) ----------
    # (source, erase region, pill right edge x, pill radius, output height)
    pills = {
        "pill_light": ("home/Lernzeit_Button_Progress.png", (262, 885, 60, 185), 942, 106, 96),
        "pill_blue": ("home/Lernzeit_Button_Continue.png", (275, 830, 55, 190), 904, 109, 96),
        "pill_green": ("parents/Buttons/Parents_Button_Backup.png", (480, 1300, 110, 330), 1399, 180, 96),
        "pill_red": ("parents/Buttons/Parents_Button_Reset_Progress.png", (380, 1575, 120, 320), 1618, 177, 96),
        "pill_cyan": ("parents/Buttons/Parents_Button_Save.png", (470, 1185, 140, 350), 1326, 204, 96),
        "pill_purple": ("parents/Buttons/Parents_Button_Enter_Parents.png", (480, 1510, 100, 380), 1602, 197, 96),
        "pill_gray": ("progress/Indicators/Lernzeit_Status_Not_Started.png", (200, 740, 40, 155), 777, 73, 72),
        "track_light": ("progress/Indicators/Lernzeit_Progress_Bar_Blue.png", None, 761, 49, 48),
    }
    caps = {}
    for name, (rel, er, x_end, radius, out_h) in pills.items():
        a = load(rel)
        if er:
            a = erase_rows(a, *er, feather=20)
        xr = x_end - radius - 12          # start of the clean right cap (straight part)
        cap = a[:, xr:, :]
        col = a[:, xr:xr + 1, :].repeat(8, axis=1)
        p = np.concatenate([cap[:, ::-1, :], col, cap], axis=1)
        s = out_h / p.shape[0]
        size = save(p, f"ui/{name}.png", max_h=out_h)
        caps[name] = (round(cap.shape[1] * s), size)
        report.append(f"{name}: skin from {os.path.basename(rel)} (text erased, right cap mirrored), {size}")

    # ---------- copies / downsizing of text-free sprites ----------
    def copy_dir(sub, out, max_w, trim=False):
        for f in sorted(os.listdir(os.path.join(SRC, sub))):
            if not f.endswith(".png"):
                continue
            a = load(f"{sub}/{f}")
            if trim:   # icons sit on large transparent canvases – crop to the artwork
                a = trim_to_main_body(a)
            save(a, f"{out}/{f}", max_w=max_w, max_h=max_w)

    copy_dir("settings/Icons", "icons", 160, trim=True)
    copy_dir("progress/Icons", "icons", 160, trim=True)
    copy_dir("parents/Icons", "icons", 192, trim=True)
    copy_dir("settings/Switches", "ui", 220)
    copy_dir("settings/Panels", "ui", 1124)
    copy_dir("progress/Panels", "ui", 560)
    save(load("progress/Buttons/Lernzeit_Progress_Button_Back.png"), "buttons/round_back.png", max_w=180)
    save(load("progress/Buttons/Lernzeit_Progress_Button_Home.png"), "buttons/round_home.png", max_w=180)

    # ---------- subject icons (rounded crops of the card artwork) ----------
    icon_boxes = {   # crop inside the card border, then round the corners
        "mathematik": ("home/Lernzeit_Button_Mathematik.png", (95, 85, 690, 630)),
        "deutsch": ("home/Lernzeit_Button_Deutsch.png", (80, 80, 700, 650)),
        "lesen": ("home/Lernzeit_Button_Lesen.png", (100, 60, 880, 640)),
        "logik": ("home/Lernzeit_Button_Logik.png", (90, 50, 700, 620)),
    }
    from PIL import ImageDraw, ImageFilter
    for sid, (rel, box) in icon_boxes.items():
        im = Image.open(os.path.join(SRC, rel)).convert("RGBA").crop(box)
        m = Image.new("L", im.size, 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius=int(min(im.size) * 0.18), fill=255)
        im.putalpha(m)
        s2 = 256 / max(im.size)
        im = im.resize((round(im.width * s2), round(im.height * s2)), Image.LANCZOS)
        save(np.asarray(im).astype(np.float32), f"icons/subject_{sid}.png")

    # ---------- Android launcher icon + Android TV banner (from the logo in the background) ----------
    full = Image.open(os.path.join(SRC, "home/Lernzeit_Main_Background_4K.png")).convert("RGB")
    book = full.crop((1130, 10, 1460, 340)).resize((432, 432), Image.LANCZOS)
    mask = Image.new("L", (432, 432), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 431, 431), radius=96, fill=255)
    icon = Image.new("RGBA", (432, 432), (0, 0, 0, 0)); icon.paste(book, (0, 0), mask)
    os.makedirs(os.path.join(DST, "branding"), exist_ok=True)
    icon.resize((192, 192), Image.LANCZOS).save(os.path.join(DST, "branding/icon_192.png"))
    book.save(os.path.join(DST, "branding/icon_adaptive_foreground_432.png"))
    sky = full.crop((1200, 500, 2640, 1310)).resize((320, 180), Image.LANCZOS)   # empty sky gradient
    logo = full.crop((1100, 20, 2740, 330))                                     # book + "Lernzeit" + sparkles
    lw = 300; lh = round(logo.height * lw / logo.width)
    logo = logo.resize((lw, lh), Image.LANCZOS)
    lm = Image.new("L", (lw, lh), 0)
    ImageDraw.Draw(lm).rounded_rectangle((6, 4, lw - 7, lh - 5), radius=18, fill=255)
    lm = lm.filter(ImageFilter.GaussianBlur(5))
    banner = sky.copy(); banner.paste(logo, ((320 - lw) // 2, (180 - lh) // 2), lm)
    banner.save(os.path.join(DST, "branding/tv_banner_320x180.png"))
    report.append("branding: icon_192, adaptive foreground, tv_banner_320x180 (cropped from main background logo)")

    with open(os.path.join(DST, "ui/caps.txt"), "w") as fh:
        for k, (cap, size) in caps.items():
            fh.write(f"{k} cap={cap} size={size[0]}x{size[1]}\n")
    print("\n".join(report))
    for k, v in caps.items():
        print(k, v)


if __name__ == "__main__":
    main()
