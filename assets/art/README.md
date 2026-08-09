# Production art

`assets/art/generated/v1` contains the first installed Locus atlas pass:
10 crafted objects, 6 visitors, 8 fixed scenery pieces, 10 material emblems,
and 8 weather/time overlays.

The home scene, crafting preview, inventory, codex, and material surfaces prefer
these assets with nearest-neighbor filtering. Deterministic Canvas primitives
remain a fallback for asset-load failure and construction progress.

Authoring sources, exact prompts, provenance, crop rules, and SHA-256 manifests
live in `artifacts/imagegen/locus-art-v1`. Run:

```bash
python3 tool/process_generated_art.py --validate-only
python3 tool/process_directional_art.py --validate-only
```

Do not hand-edit installed PNGs. Update the source sheet or processing contract,
rebuild the package, and review the contact sheet and simulator composition.

Directional placement paths live in `assets/content/placement_catalog.json`.
The `locus-directional-art-v1` authoring package provides 10 objects × 4 true
quarter-turn sprites under `assets/art/generated/v1/directional`. Each recipe
direction has an independent PNG and hash; no production direction depends on
runtime mirroring. Selection tiles, valid-anchor markers, and direction controls
remain code-rendered because they must scale and respond to interaction state.
