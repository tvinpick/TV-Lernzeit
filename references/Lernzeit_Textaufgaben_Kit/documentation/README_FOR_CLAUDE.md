# Textaufgaben — Lernzeit

One 1920×1080 grass-and-pond background with empty space at the top for a runtime-rendered question, ten transparent 200×200 PNG objects, and 30 arithmetic tasks with answers between 0 and 10. No baked writing or digits in images.

All questions, operands, operation and correct answer are in `documentation/textaufgaben.json`. `picture` is relative to `Game_Assets/Objects/`. Use `a`, `b`, `op` and `answer` to verify or grade, rather than parsing natural-language text. Use arrows + OK to select answers.

Language is German (UTF-8). German plural forms in the text were chosen to avoid singular ambiguity. Objects should be drawn as separate instances, not concatenated into one sprite. If using simple visual arithmetic, for subtraction show initial group and remove (or cross out) b items dynamically.

Reference_Only is not to be imported as a game asset. These images combine some earlier vocabulary art with new lightweight vector-style icons.

## JSON placement
All datasets intended for runtime use are stored under `Game_Assets/Data/` (not just in documentation). Import them into Godot alongside PNG assets.
