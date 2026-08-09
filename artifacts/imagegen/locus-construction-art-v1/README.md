# Locus construction art v1

This package adds a bounded recipe-specific construction layer to the shared
Locus renderer. It contains three authored progress states for each of the ten
recipes: foundation (25%), frame (60%), and finish (85%). Completed objects
continue to use the directional placement catalog.

The package deliberately does **not** bake every weather × surroundings × time
combination. Those inputs remain deterministic runtime treatments: weather
skin/palette, time palette, and connector marks. This keeps the asset inventory
reviewable while preserving recipe identity.

## Provenance and installation

- Generator: OpenAI built-in `image_gen`, 2026-08-09.
- Style references: the tracked v1 object source sheet and both tracked
  directional source sheets.
- Exact prompts: `PROMPTS.md`.
- Raw candidates: `sources/construction-a.png` and
  `sources/construction-b.png`.
- Deterministic processor: `tool/process_construction_art.py`.
- Runtime catalog: `assets/content/crafting_art_catalog.json`.
- Runtime output: `assets/art/generated/v1/construction/`.

Run:

```bash
python3 tool/process_construction_art.py
python3 tool/process_construction_art.py --validate-only
```

The generated sheets did not always place the strongest 85% state in the
third source column. The processor records the reviewed source-cell mapping in
the manifest and installs a monotonic runtime order instead of hiding that
authoring detail.
