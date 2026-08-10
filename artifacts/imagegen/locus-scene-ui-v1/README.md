# Locus Scene and UI Art v1

This package adds 50 production pixel-art assets without expanding the recipe
catalog or introducing a parallel visual system. The generated details support
the existing night-neighborhood identity in four runtime roles:

- 20 deterministic terrain details
- 10 weather and time atmosphere details
- 10 placement-editor markers
- 10 action emblems for high-frequency controls

The five source atlases were generated with OpenAI ImageGen using the existing
Locus and collection-expansion contact sheets as strict style references. Run
`python3 tool/process_scene_ui_art.py` to remove the magenta chroma key, crop the
cells, produce 50 distinct RGBA runtime PNGs, write the hash manifest, and build
the visual review contact sheet.

Runtime output lives under `assets/art/generated/v1/{terrain,atmosphere,editor,action}`.
