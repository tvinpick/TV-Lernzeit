LERNZEIT — STICKER ALBUM | v1.0
20 separate sticker assets for a reward album.

Folder: Mascot/Stickers/
Naming: Sticker_01.png … Sticker_20.png
Image format: 300 x 300 PNG RGBA with real alpha transparency.
Exactly one sticker per file; no atlas, no text or numbers inside sticker imagery.
All images have at least 5% transparent padding at their nearest edge.

Sticker order:
01-05 Animals: Cat, Dog, Rabbit, Fox, Panda
06-10 Transport: Car, Excavator, Airplane, Train, Bus
11-15 Space: Rocket, UFO, Astronaut, Planet, Moon
16-20 Food: Burger, IceCream, Cupcake, Pizza, Popcorn

Integration (Godot):
- Load each image independently as a texture for a TextureRect or TextureButton.
- Recommended display size is 96-200 px; do not upsize source textures.
- Enable filter/linear sampling; use Keep Aspect Centered or equivalent.
- Store unlock state by the sticker ID 01..20, not by image data.
- This pack includes no text labels and no large background textures.

ASSET_MANIFEST.json supplies the exact filename, path, size, category,
and English-language icon description for each PNG.
