# Locus weather treatments v1

This bounded shared layer pack replaces a potential 300–3,600 full-sprite
combination matrix with twelve reusable assets: six sparse object-surface
patterns and six isometric footprint effects. It is registered in
`assets/content/visual_layer_catalog.json` for the next shared-compositor
slice. The current renderer does not composite it yet.

- Generator: OpenAI built-in `image_gen`, 2026-08-09.
- Style reference: tracked directional-object contact sheet.
- Exact prompts: `PROMPTS.md`.
- Raw sources: `sources/`.
- Deterministic processor: `tool/process_weather_art.py`.
- Installed assets: `assets/art/generated/v1/weather/`.
- Reviewed chroma removal: 28% ImageMagick fuzz; the lower threshold preserves
  intentional violet/cloud and warm-magenta motif pixels.

```bash
python3 tool/process_weather_art.py
python3 tool/process_weather_art.py --validate-only
```

Surface patterns are intended to be alpha-clipped to the object sprite.
Footprint effects render below the object and above the isometric tile. Time
palette and surroundings connectors remain runtime treatments.
