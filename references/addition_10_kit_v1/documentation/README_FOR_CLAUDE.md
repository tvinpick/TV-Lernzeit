# Lernzeit: Addition bis 10 — Godot 4 / Android TV

This package contains a REAL set of individually usable, transparent PNGs plus SIX rendered mockups. The rendered mockups under `Concepts/` are VISUAL REFERENCES ONLY: never embed them as an entire interactive screen.

## Key choices
- Resolution: 1920x1080 reference viewport, scalable to 3840x2160 TV output.
- `Backgrounds/Lernzeit_Addition_10_Background_4K.png` is natively authored at 3840x2160; it is the only full-screen opaque background.
- `Addition_UI/` assets are transparent RGBA images, including blank panels. The plus, equal and question symbols can alternatively be rendered as crisp text.
- `Shared_Objects/` repeats a small number of existing PNG sprites for convenience. Prefer the existing `math/shared_ui/` and math objects folders when they are already installed, to avoid duplication in the final Godot project.
- `Counting_Extras/` contains requested supplementary dots/dice 1–6 and ready-numbered cards 0–10. Prefer a blank card plus programmatic text for font consistency.
- `Deutsch_Fix/Deutsch_Letter_Button_Focused.png` replaces the focused asset with a true transparent-corner version. Copy over the old file only after checking existing resource references; no dark or grey rectangular matte should remain.
- All letters, numbers, options, questions and progress dots should be generated dynamically in Godot; NONE should be read from the static mockup. The six examples are intentionally mathematically valid.

## Exercises (all in number range 0..10)
01. Count apple groups: 3 + 2 = 5.
02. Calculate: 4 + 3 = 7.
03. Complete to ten: 6 + ? = 10; missing = 4. Frame shows exactly six counters.
04. Count dice: 3 + 4 = 7.
05. Missing addend: 2 + ? = 5; missing = 3.
06. Find matching equation: three stars plus two stars; 3 + 2.

## Godot implementation
Use TextureRect children for sprites and separate Label / RichTextLabel for text. `TextureButton` or Button with focus neighbor navigation should receive focus, **not** the full-screen background. `TextureRect.mouse_filter = IGNORE` for decoration. `focus_mode = FOCUS_ALL` and explicit neighbor focus order for TV D-pad.

Use a single generator with `a` and `b` in [0,10] and `a + b <= 10`, distractors unique and within [0,10]. For missing-addend mode generate `a + ? = sum` with sum<=10. Always validate the count of sprites, dice, dots, and correctness of equation BEFORE displaying. Never give the answer away with a permanently selected correct button; bright button in mockups indicates the focused button only, which moves with the remote.

Do not assume default-language setting changes learning content: mathematical labels can localize de/ru; the actual German-language learning tasks remain German when those modules are active. Session length: 10 exercises. Keep source image filenames in English.

## Audio
Audio is not included. Expose optional hooks for German number pronunciations and spoken task instructions; no fake speech recordings.
