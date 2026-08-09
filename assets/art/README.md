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
```

Do not hand-edit installed PNGs. Update the source sheet or processing contract,
rebuild the package, and review the contact sheet and simulator composition.
