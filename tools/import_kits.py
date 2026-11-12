#!/usr/bin/env python3
"""Unpacks the Lernzeit graphics kits (ZIP files in the repository root) and
sorts their files into the Godot project and the reference folder.

  * runtime sprites  -> lernzeit/assets/<kit>/...   (imported by Godot, used as single textures)
  * full backgrounds -> lernzeit/assets/<kit>/backgrounds/*_1080p.png (downscaled 3840x2160 -> 1920x1080,
                        the app UI renders at 1080p; originals stay in the ZIP)
  * mock-up screens, concept art, previews, README/manifest
                     -> references/<kit>/...       (outside the Godot project: never loaded as screens)

Safety: an existing target file is never overwritten. Same content -> "already present";
different content -> reported as CONFLICT and left untouched.

It also checks every PNG against the kit's ASSET_MANIFEST.json (size, RGBA, transparency)
and generates lernzeit/scripts/data/KitAssets.gd (registry of all runtime textures).

Usage: python3 tools/import_kits.py            (run from the repository root)
"""
import hashlib, io, json, os, re, sys, zipfile
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "lernzeit")
REFS = os.path.join(ROOT, "references")

# zip name -> (kit id, rules). A rule maps a path prefix inside the kit to
# ("asset"|"background"|"reference", target directory relative to assets/ or references/)
KITS = {
    "Lernzeit_Deutsch_Buchstaben_Complete_Kit_v1.zip": ("deutsch_buchstaben", [
        ("Backgrounds/", "background", "deutsch/backgrounds"),
        ("Pictures/", "asset", "deutsch/pictures"),
        ("UI/Controls/", "asset", "deutsch/ui/controls"),
        ("UI/Feedback/", "asset", "deutsch/ui/feedback"),
        ("UI/Letter_Buttons/", "asset", "deutsch/ui/letter_buttons"),
        ("UI/Panels/", "asset", "deutsch/ui/panels"),
        ("UI/Progress/", "asset", "deutsch/ui/progress"),
        ("UI/Word_Tiles/", "asset", "deutsch/ui/word_tiles"),
        ("Screens_1920x1080/", "reference", "deutsch_buchstaben_kit_v1/screens_1920x1080_mockups"),
        ("Visual_References/", "reference", "deutsch_buchstaben_kit_v1/visual_references"),
        ("Previews/", "reference", "deutsch_buchstaben_kit_v1/previews"),
        ("Documentation/", "reference", "deutsch_buchstaben_kit_v1/documentation"),
    ]),
    "Lernzeit_Subtraction_10_Complete_Kit.zip": ("subtraction_10", [
        ("Lernzeit_Subtraction_10_Kit_v1/Backgrounds/", "background", "math/subtraction_10/backgrounds"),
        ("Lernzeit_Subtraction_10_Kit_v1/Subtraction_Icons/", "asset", "math/subtraction_10/icons"),
        ("Lernzeit_Subtraction_10_Kit_v1/Subtraction_Tools/", "asset", "math/subtraction_10/tools"),
        ("Lernzeit_Subtraction_10_Kit_v1/Shared_UI/", "asset", "math/shared_ui"),
        ("Lernzeit_Subtraction_10_Kit_v1/Concepts/", "reference", "subtraction_10_kit_v1/concepts"),
        ("Lernzeit_Subtraction_10_Kit_v1/Previews/", "reference", "subtraction_10_kit_v1/previews"),
        ("Lernzeit_Subtraction_10_Kit_v1/Documentation/", "reference", "subtraction_10_kit_v1/documentation"),
    ]),
    # Only finished mock-up screens with baked German text and numbers, no README/manifest.
    "Lernzeit_Counting_10_Six_New_Screens.zip": ("counting_10", [
        ("", "reference", "counting_10_screens_mockups"),
    ]),
    "Lernzeit_Addition_10_Counting_Extras_Deutsch_Fix.zip": ("addition_10", [
        ("Lernzeit_Addition_10_Kit_v1/Backgrounds/", "background", "math/addition_10/backgrounds"),
        ("Lernzeit_Addition_10_Kit_v1/Addition_UI/", "asset", "math/addition_10/ui"),
        ("Lernzeit_Addition_10_Kit_v1/Counting_Extras/Dice/", "asset", "math/counting_10/dice"),
        ("Lernzeit_Addition_10_Kit_v1/Counting_Extras/Number_Cards/", "asset", "math/counting_10/number_cards"),
        ("Lernzeit_Addition_10_Kit_v1/Counting_Extras/Shared/", "asset", "math/counting_10"),
        ("Lernzeit_Addition_10_Kit_v1/Counting_Extras/", "asset", "math/counting_10"),
        ("Lernzeit_Addition_10_Kit_v1/Shared_Objects/", "asset", "math/shared_ui"),
        # README: replaces the focused letter button (old one had a grey rectangular matte)
        ("Lernzeit_Addition_10_Kit_v1/Deutsch_Fix/", "replace", "deutsch/ui/letter_buttons"),
        ("Lernzeit_Addition_10_Kit_v1/Concepts/", "reference", "addition_10_kit_v1/concepts"),
        ("Lernzeit_Addition_10_Kit_v1/Previews/", "reference", "addition_10_kit_v1/previews"),
        ("Lernzeit_Addition_10_Kit_v1/Documentation/", "reference", "addition_10_kit_v1/documentation"),
    ]),
    "Lernzeit_Deutsch_Alphabet_38_PNG.zip": ("deutsch_alphabet_38", [
        ("PNG/", "asset", "deutsch/words"),                 # README: res://assets/deutsch/words/
        ("Preview/", "reference", "deutsch_alphabet_38"),
        ("README_FOR_CLAUDE.txt", "reference", "deutsch_alphabet_38"),
        ("ASSET_MANIFEST.json", "reference", "deutsch_alphabet_38"),
    ]),
    # Identical to the progress art that is already integrated (lernzeit/assets/ui, icons).
    "Lernzeit_Progress_UI_Assets.zip": ("progress_ui", [
        ("", "skip", ""),
    ]),
}


# Sprites whose crop contains a sliver of a neighbouring sprite from the source atlas:
# columns outside the main body are made transparent (canvas size unchanged).
CLEAN_STRAYS = {"Counter_Green.png", "Counting_Dice_3.png", "Car_Blue.png", "Counting_Dice_5.png"}


def clean_strays(data):
    im = Image.open(io.BytesIO(data)).convert("RGBA")
    a = np.asarray(im).copy()
    m = (a[:, :, 3] > 12).sum(0) > 0
    runs, s = [], None
    for i, v in enumerate(m):
        if v and s is None:
            s = i
        if not v and s is not None:
            runs.append((s, i)); s = None
    if s is not None:
        runs.append((s, len(m)))
    x0, x1 = max(runs, key=lambda r: r[1] - r[0])
    a[:, :x0, 3] = 0
    a[:, x1:, 3] = 0
    buf = io.BytesIO()
    Image.fromarray(a, "RGBA").save(buf, "PNG", optimize=True)
    return buf.getvalue()


def pixel_key(data):
    im = Image.open(io.BytesIO(data)).convert("RGBA")
    return hashlib.sha256(im.tobytes() + str(im.size).encode()).hexdigest()


def existing_pixels():
    out = {}
    for dp, _, fs in os.walk(os.path.join(PROJ, "assets")):
        for f in fs:
            if f.endswith(".png"):
                p = os.path.join(dp, f)
                out[pixel_key(open(p, "rb").read())] = os.path.relpath(p, PROJ)
    return out


def sha(b):
    return hashlib.sha256(b).hexdigest()


def safe_write(path, data, log):
    rel = os.path.relpath(path, ROOT)
    if os.path.exists(path):
        old = open(path, "rb").read()
        if sha(old) == sha(data):
            log["already_present"].append(rel)
        else:
            log["conflicts"].append(rel)
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    log["written"].append(rel)
    return True


def png_info(data):
    im = Image.open(io.BytesIO(data))
    a = np.asarray(im.convert("RGBA"))[:, :, 3]
    return {"width": im.width, "height": im.height, "mode": im.mode,
            "transparent_ratio": round(float((a < 250).mean()), 3)}


def main():
    log = {"written": [], "already_present": [], "conflicts": [], "skipped": [], "warnings": [],
           "duplicates": [], "cleaned": [], "replaced": []}
    registry = {}
    known = existing_pixels()
    # files that a later kit explicitly replaces (e.g. Deutsch_Fix) are not written from older kits
    superseded = set()
    for zname, (kit, rules) in KITS.items():
        zpath = os.path.join(ROOT, zname)
        if not os.path.exists(zpath):
            continue
        for n in zipfile.ZipFile(zpath).namelist():
            r = next((r for r in rules if n.startswith(r[0])), None)
            if r and r[1] == "replace" and not n.endswith("/"):
                superseded.add(os.path.join(PROJ, "assets", r[2], os.path.basename(n)))
    for zname, (kit, rules) in KITS.items():
        zpath = os.path.join(ROOT, zname)
        if not os.path.exists(zpath):
            log["warnings"].append(f"{zname}: not found")
            continue
        z = zipfile.ZipFile(zpath)
        names = [n for n in z.namelist() if not n.endswith("/")]
        manifest = {}
        for n in names:
            if n.endswith("ASSET_MANIFEST.json"):
                d = json.loads(z.read(n))
                items = d["assets"] if isinstance(d, dict) else d
                base = n[:n.rfind("Documentation/")] if "Documentation/" in n else n[:n.rfind("/") + 1]
                for it in items:
                    if "size" in it:   # newer manifest format: "size": [w, h]
                        it = dict(it, width=it["size"][0], height=it["size"][1])
                    if "path" not in it and "filename" in it:   # alphabet pack: {"filename": ...} in PNG/
                        it = dict(it, path="PNG/" + it["filename"])
                    manifest[base + it["path"]] = it
        for n in sorted(names):
            fname = os.path.basename(n)
            if not re.match(r"^[A-Za-z0-9_.-]+$", fname):
                log["warnings"].append(f"{zname}: unusual file name {n}")
            rule = next((r for r in rules if n.startswith(r[0])), None)
            if rule is None:
                log["warnings"].append(f"{zname}: no rule for {n}")
                continue
            kind, target = rule[1], rule[2]
            data = z.read(n)
            if kind == "skip":
                log["skipped"].append(f"{zname}:{n}")
                continue
            if fname.lower().endswith(".png"):
                info = png_info(data)
                m = manifest.get(n)
                if m:
                    if (m["width"], m["height"]) != (info["width"], info["height"]):
                        log["warnings"].append(f"{n}: size {info['width']}x{info['height']} != manifest {m['width']}x{m['height']}")
                    if m.get("mode") == "RGBA" and info["mode"] != "RGBA":
                        log["warnings"].append(f"{n}: mode {info['mode']} != RGBA")
                    if m.get("transparent") is True and info["transparent_ratio"] == 0:
                        log["warnings"].append(f"{n}: manifest says transparent, image has no alpha")
                elif manifest and kind != "reference":
                    log["warnings"].append(f"{n}: not listed in manifest")
                if kind == "asset" and info["mode"] != "RGBA":
                    log["warnings"].append(f"{n}: runtime sprite without alpha channel")
            if kind == "reference":
                safe_write(os.path.join(REFS, target, fname), data, log)
            elif kind == "replace":
                dst = os.path.join(PROJ, "assets", target, fname)
                _info = png_info(data)
                registry[target.replace("/", "_") + "/" + os.path.splitext(fname)[0]] = (
                    "res://assets/%s/%s" % (target, fname), _info["width"], _info["height"])
                if os.path.exists(dst) and sha(open(dst, "rb").read()) != sha(data):
                    backup = os.path.join(REFS, "replaced", target.replace("/", "_") + "__" + fname)
                    if not os.path.exists(backup):
                        os.makedirs(os.path.dirname(backup), exist_ok=True)
                        with open(backup, "wb") as fb:
                            fb.write(open(dst, "rb").read())
                    with open(dst, "wb") as fo:
                        fo.write(data)
                    log["replaced"].append(os.path.relpath(dst, ROOT) + " (old copy: references/replaced/)")
                else:
                    safe_write(dst, data, log)
            elif kind == "asset":
                dst = os.path.join(PROJ, "assets", target, fname)
                if dst in superseded:
                    log["skipped"].append(f"{zname}:{n} (superseded by a fixed version)")
                    continue
                if fname in CLEAN_STRAYS:
                    data = clean_strays(data)
                    log["cleaned"].append(f"{n}: removed sliver of neighbouring sprite")
                pk = pixel_key(data)
                if pk in known and known[pk] != os.path.relpath(dst, PROJ):
                    log["duplicates"].append(f"{n} = {known[pk]} (same pixels, not copied)")
                    continue
                if safe_write(dst, data, log):
                    known[pk] = os.path.relpath(dst, PROJ)
                info = png_info(data)
                key = target.replace("/", "_") + "/" + os.path.splitext(fname)[0]
                registry[key] = ("res://assets/%s/%s" % (target, fname), info["width"], info["height"])
            elif kind == "background":
                im = Image.open(io.BytesIO(data)).convert("RGB").resize((1920, 1080), Image.LANCZOS)
                buf = io.BytesIO()
                im.save(buf, "PNG", optimize=True)
                out = re.sub(r"_4K\.png$", "", fname) + "_1080p.png"
                safe_write(os.path.join(PROJ, "assets", target, out), buf.getvalue(), log)
                key = target.replace("/", "_") + "/" + os.path.splitext(out)[0]
                registry[key] = ("res://assets/%s/%s" % (target, out), 1920, 1080)

    # GDScript registry
    lines = [
        "class_name KitAssets",
        "extends RefCounted",
        "## Registry of the exercise graphics kits (generated by tools/import_kits.py – do not edit).",
        "## Every entry is a separate texture resource; mock-up screens are NOT part of the app",
        "## (they live in /references outside the Godot project).",
        "## key -> [path, width, height]",
        "",
        "const TEXTURES := {",
    ]
    for k in sorted(registry):
        p, w, h = registry[k]
        lines.append('\t"%s": ["%s", %d, %d],' % (k, p, w, h))
    lines += [
        "}",
        "",
        "",
        "static func path(key: String) -> String:",
        "\treturn TEXTURES[key][0] if TEXTURES.has(key) else \"\"",
        "",
        "",
        "static func texture(key: String) -> Texture2D:",
        "\tvar p := path(key)",
        "\treturn load(p) if p != \"\" else null",
        "",
        "",
        "static func keys_with_prefix(prefix: String) -> Array:",
        "\treturn TEXTURES.keys().filter(func(k): return k.begins_with(prefix))",
        "",
    ]
    reg_path = os.path.join(PROJ, "scripts", "data", "KitAssets.gd")
    content = "\n".join(lines)
    if os.path.exists(reg_path) and open(reg_path).read() != content:
        open(reg_path, "w").write(content)   # generated file: regenerate on change
        log["written"].append(os.path.relpath(reg_path, ROOT) + " (regenerated)")
    elif not os.path.exists(reg_path):
        open(reg_path, "w").write(content)
        log["written"].append(os.path.relpath(reg_path, ROOT))

    json.dump(log, open(os.path.join(REFS, "import_report.json"), "w") if os.path.isdir(REFS) else sys.stdout,
              indent=1, ensure_ascii=False)
    for k in ("written", "already_present", "conflicts", "skipped", "duplicates", "cleaned", "replaced", "warnings"):
        print(f"{k}: {len(log[k])}")
        if k in ("conflicts", "warnings", "duplicates", "cleaned", "replaced"):
            for x in log[k]:
                print("   ", x)
    print("registry entries:", len(registry))
    return 1 if log["conflicts"] else 0


if __name__ == "__main__":
    sys.exit(main())
