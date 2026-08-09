# Locus Collection Expansion v1

This production pack expands the deterministic diorama catalog from 10 to 28
placeable objects and from 6 to 18 visitors. The source atlases were generated
with OpenAI ImageGen against the existing Locus directional, construction, and
visitor reference sheets. No generated lettering or UI chrome is shipped.

## Sources

- `directional-street.png`, `directional-garden.png`, `directional-night-market.png`
- `construction-street.png`, `construction-garden.png`, `construction-night-market.png`
- `visitors-a.png`, `visitors-b.png`

## Runtime output

Run `python3 tool/process_collection_expansion.py` to key the magenta backdrop,
crop the atlas cells, and produce 156 RGBA runtime assets:

- 18 base object sprites
- 72 directional object sprites
- 54 construction-stage sprites
- 12 visitor sprites

`manifest.json` records the source and output dimensions and SHA-256 hashes.
`contact-sheet.png` is the visual review surface for all 30 new subjects.
