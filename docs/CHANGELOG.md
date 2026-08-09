# Changelog

## Unreleased

### Fixed

- iOS simulator installation now has valid executable bundle metadata.
- iOS cold launch no longer stops on a direct WAL pragma in sqflite.
- Deterministic demo capture and crafting no longer request unavailable real
  Bluetooth or Motion permissions.
- Demo steps initialize to the deterministic 4,275-unit source.
- Deterministic demo data now uses its own SQLite database and cannot affect a
  production-mode launch.
- Compact codex cards and the crafting detail preview retain usable layout at
  narrow widths and larger text sizes.
- Objects returned to storage remain in the placement catalog and can be
  direction-adjusted and placed again on the first validated empty cell.

### Changed

- User-visible app identity is Locus.
- Capture uses a surroundings/sensor glyph instead of a camera glyph.
- Home, crafting, inventory, and codex object visuals share deterministic
  geometry, weather and capture-time palettes, connector marks, construction
  state, and `visualSeed` detail channels.
- New crafts use the `object-v2` visual contract while saved `object-v1`
  collectibles retain their previous geometry.
- Native launch background generation uses Locus navy `#071522`.
- Added `pubspec.lock` so application dependency resolution is reproducible.
- Placement editing now presents placed objects as an artwork catalog with
  direction, rotated footprint, and available-anchor information.
- The board highlights the selected footprint and valid anchors while dimming
  unrelated connections; invalid direction-pad and rotation actions are
  disabled before persistence.
- Directional artwork and allowed rotations now come from
  `assets/content/placement_catalog.json`; every direction resolves to a unique
  production sprite rather than an interim mirror transform.
- Crafting previews now show the authored construction stage that current
  available steps can reach, and incomplete object previews use the same
  cataloged recipe stage.
- Placement movement now follows the four visible isometric diagonals with
  48 dp controls. Material and placed-object selections expose semantic state,
  and tappable pixel cards show visible pressed ink.

### Assets

- Added one normalized Pro-generated AppIcon candidate and its complete prompt.
  It is intentionally not selected as the shipping icon yet.
- Added 42 production-bound pixel-art assets covering every MVP object and
  visitor plus fixed scenery, materials, weather, and time-of-day effects.
- Added the five original ImageGen sheets, exact prompts, a labeled contact
  sheet, crop/install tooling, and a manifest recording dimensions and hashes.
- Added two tone-matched directional source atlases and 40 transparent runtime
  sprites covering all ten placeable objects in four true quarter-turn views.
- Added a directional contact sheet, exact inventory/hash manifest, reviewed
  crop bounds, and a standalone reproducible processing/validation tool.
- Added 30 construction sprites covering all ten recipes at foundation, frame,
  and finish stages, with raw ImageGen sources, exact prompts, reviewed cell
  ordering, contact sheet, SHA-256 manifest, and reproducible processor.
- Added 12 shared weather-treatment assets (six surface patterns and six
  footprint effects), plus exact prompt/source/hash provenance and a visual
  layer catalog for the upcoming shared compositor.
- Generated art is now used by the home scene, object previews, inventory,
  codex, visitor goal, and material indicators; Canvas rendering remains the
  deterministic fallback.
- Tuned weather/time overlay opacity after simulator review so atmospheric
  pixels do not obscure the daytime neighborhood grid.

### Tests

- Added exhaustive placement-catalog tests across every recipe, four rotations,
  all board edges, collision rejection, unsupported directions, art files, and
  iOS-sized movement targets.
- Added exact crafting-art and weather-layer catalog coverage, stage-resolution,
  file-existence, and 48 dp isometric movement tests.
