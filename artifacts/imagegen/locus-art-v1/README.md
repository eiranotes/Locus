# Locus generated art v1

This package records the production-bound ImageGen sources, prompts, crop
contract, and installed runtime assets for the first Locus atlas pass.

## Inventory

- 10 crafted objects;
- 6 visitors;
- 8 fixed scenery pieces;
- 10 weather/surroundings material emblems;
- 8 weather/time overlays.

The five source sheets were produced with the built-in OpenAI `image_gen` tool
on 2026-08-09. The existing Locus AppIcon candidate was supplied as a style
reference only. Every request used a flat `#FF00FF` authoring background and
explicitly prohibited that color inside the subjects.

## Processing

```bash
python3 tool/process_generated_art.py
python3 tool/process_generated_art.py --validate-only
```

Processing requires ImageMagick. It keys the generated background, isolates the
declared grid cells, uses nearest-neighbor downscaling, anchors scenery and
characters, installs RGBA PNGs under `assets/art/generated/v1`, and writes
`manifest.json` with source/output dimensions and SHA-256 hashes.

Validation uses the Python standard library only. It rejects missing or extra
assets, non-RGBA outputs, dimension drift, source drift, and hash drift.

The generated sprites are primary runtime art. Deterministic Canvas geometry
remains a fail-safe when an asset cannot load; it is not the preferred visual.

`contact-sheet.png` is the labeled inventory review, and
`simulator-home.png` records the installed v1 package on an iPhone 16 Pro iOS
26.5 simulator in deterministic demo mode. Daytime lighting overlays are
suppressed so atmospheric sprites do not obscure the neighborhood grid.
