# Lesen — Sätze und Mini-Texte

This pack contains 30 different 480×360 no-text scenes, `saetze.json` (one image per sentence), eight mini-texts with comprehension questions in `texte.json`, and independent 300×300 RGBA answer sprites.

Use only `Game_Assets/` in Godot. `Reference_Only/` is **not** part of the game. All written German text comes from JSON; no text is burned into the pictures.

## Critical reading logic
Show the sentence **without playing spoken audio before answering**. Once a correct choice is made, the corresponding prerecorded spoken sentence can play. Mini-texts use three multiple-choice answer pictures; the field `correct` is 0-based.

Keep choice buttons large enough for TV arrows + OK. For questions requiring a 3-picture choice, select the correct picture and randomly choose two different scene images. Do not accidentally use near-identical images as distractors.

Scene and answer images reuse previously established vocabulary artwork whenever possible; backgrounds are original minimal vector-style panels. Pictures are not photographic, and are not exact clones of the original glossy illustrations.

## Language / validation
German text is stored in UTF-8 JSON, with correct capitalization and punctuation. All referenced images exist in `Game_Assets/`. One `Antwort_*.png` equivalent is provided as `Answer_*.png` for every mini-text option.

## JSON placement
All datasets intended for runtime use are stored under `Game_Assets/Data/` (not just in documentation). Import them into Godot alongside PNG assets.
