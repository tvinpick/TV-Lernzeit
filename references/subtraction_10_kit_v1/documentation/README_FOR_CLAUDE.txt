LERNZEIT — SUBTRACTION BIS 10 ASSET PACK v1
==========================================
Sony BRAVIA 3 / Android TV 12 / Godot 4.x / German default, Russian UI alternate.

Concepts/: Six STATIC design references, 1672x941 PNG, NOT functional screens. Each shows a mathematically consistent subtraction exercise: 7-2=5, 8-3=5, 9-3=6, 8-3=5 on the number line, 8-3=5 in the ten-frame, and choose five stars for 7-2=5. Some sample button highlights coincide with the answer; generate focus independently during runtime.
Backgrounds/: Distinct sky-blue/peach 3840x2160 artwork (drawn programmatically at target resolution), NO buttons or words.
Subtraction_Icons/: standalone RGBA-minus, equals, red strike overlay and optional faded removed counter. Draw equation digits in Godot, not in images.
Subtraction_Tools/: transparent blank calculation panels, empty ten-frame, unlabeled number line, backward hop arrow, number-line markers. Render number labels dynamically using scene data.
Shared_UI/: reusable transparent RGBA sprites copied from approved existing counting UI kit, including answer buttons, states, common items, feedback, progress and navigation.

Implementation guidelines:
- Never use a complete Concept image as an interactive exercise. Compose UI and draw live text/questions/answers.
- Generate a,b in 0..10 where b<=a. Answer a-b (nonnegative). Support a=0 as later stage.
- On crossed-out object screens: create a object sprites, add strike overlay to b objects, leave a-b uncrossed.
- On ten-frame screens: create a counters occupying cells left-to-right/top-to-bottom and cross b; never hardcode filled cell counts.
- Number-line: label 0..10 in Godot, start at a, step LEFT b times, endpoint a-b; number-line graphics are purely decorative.
- Missing subtrahend: draw a - ? = c; correct missing number a-c.
- Build four large TV focusable buttons; navigate with DPAD; OK confirm; Back always returns safely.
- Overlay translated UI strings. Default de; ru translated interface; mathematical content remains aligned with German first-class curriculum.
- Track errors and task category in progress statistics. No forced time limits.
- For larger ranges switch config, backgrounds and pedagogical representations rather than re-creating full screens.
- All sprites except full backgrounds and six concept mockups have true transparent alpha (RGBA).
