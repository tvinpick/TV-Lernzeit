# Lernzeit — Deutsch / Buchstaben — UI Kit v1

## Purpose
This pack provides a reusable RTL-free television-focused GUI for the first-grade German language alphabet exercises. It is intended for Sony BRAVIA 3 / Android TV 12 using Godot 4.x, standard 16:9 landscape view, controlled with a TV D-pad + OK + Back.

## Structure
- Backgrounds: one 3840x2160 clean purple-lilac background with no baked text or buttons.
- UI: separate transparent PNGs (question/header/content panels, answer states, audio controls, progress dots, word slots and letters).
- Pictures: isolated pictograms for Maus, Apfel, Auto, Sonne, Fisch, Haus, Ball and Stern.
- Screens_1920x1080: six demonstration screens composed from the reusable UI assets; for visual reference only, NOT interactive and DO NOT load them as the actual lesson screen.
- Visual_References: six additional artist concepts; the extra decorations may differ from the minimal TV implementation and should not be baked into the UI.

## The six exercise modes
1) FIND_LETTER — prompt: 'Finde den Buchstaben M!' options N/M/W/H, correct M.
2) LISTEN_PHONEME — play German /m/ phoneme, choose M among A/M/S/O. Letter name ('em') is NOT the same thing as the phoneme /m/.
3) UPPERCASE_LOWERCASE — target M, choose m from m/n/w/h.
4) FIRST_SOUND — show picture Maus, prompt 'Mit welchem Laut beginnt „Maus“?', options M/S/L/B.
5) MISSING_LETTER — M _ M A, options A/O/E/I.
6) BUILD_WORD — target MAMA, answer tiles should be shuffled (in sample A/M/A/M), four slots. Support select-then-place via remote; no drag-only interaction.

## Important Godot implementation requirements
- Keep all text, letters, numbers and progress counts as live labels in Godot. Draw absolutely no answer text into texture assets.
- At start of exercise, current focus is clearly visible. Use Control/Button and directional focus_neighbor_*; OK submits; Android Back goes to prior menu with progress preserved appropriately.
- Reuse the same screen layout and UI textures for all alphabet exercises; change data only: type, prompt, correct answer, options, image, audio and unlocked letter set.
- For AUDIO exercises, bundle locally recorded native German sound clips. Sample mockup has NO actual speech audio.
- The game interface language defaults to German; Russian is optional for navigation/instructions. German target words and phonemes stay German.
- Parent section tracks Gelernte Buchstaben (learned letters). Only introduce words built from letters already unlocked, except when explicitly previewed/introduced. Store per-topic statistics separately.
- Do not implement a mascot or a room; this kit deliberately has a quieter real UI than some more decorative illustration references.
- Exercise session can contain 10 items, progress 1/10..10/10. Never award progress for wrong answers; record attempts distinctly.
- Correct answers must be stored in exercise data, not inferred from which option looks highlighted in a screenshot.
- Responsive design reference is 1920x1080; background is 3840x2160 to support 4K, UI scaled via anchors/containers for overscan/safe areas. Keep 6% outer safe margins on TV.
- Use UI/Panels textures with Godot StyleBoxTexture nine-patch stretching where appropriate; avoid scaling fixed corner radii horizontally.
- Images in Pictures have transparent alpha; no solid checkerboard in PNG files.
- Progress must remain local/offline. Do not collect personal information by default.

## Suggested scene/data organization
res://scenes/deutsch/DeutschExercise.tscn
res://scripts/deutsch/DeutschExerciseGenerator.gd
res://scripts/deutsch/DeutschExerciseSession.gd
res://scripts/deutsch/LetterProgressRepository.gd
res://data/deutsch/letters.json
res://assets/deutsch/ (this kit)

## Example data
{
  "id": "first_sound_maus_01", "mode": "FIRST_SOUND", "question_key": "first_sound",
  "word": "Maus", "picture": "Pictures/Deutsch_Picture_Maus.png", 
  "target_letter": "M", "options": ["M", "S", "L", "B"], "correct": "M",
  "audio_path": "res://audio/de/maus.ogg"
}

## Notes
All original visual references in Visual_References were generated illustrations, not production-ready screen states. The six Screens_1920x1080 are consistency mockups assembled for Godot implementation, not screenshots of an app.
