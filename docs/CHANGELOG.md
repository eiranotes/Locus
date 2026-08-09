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
- Adaptive list controls inside cards and tonal capture sections now paint
  their Material selection and ink response without a hidden-splash framework
  assertion.

### Changed

- Expanded the deterministic collection to 28 recipes and 18 visitors while
  preserving the 5×5 board, eight-active-object limit, offline loop, and
  non-monetized steps/weather/visitor progression.
- Added three named expansion sets with six immediately craftable objects and
  twelve visitor-reward recipes; every visitor still exposes at most three
  conditions.
- Codex tabs now show overall completion and section the larger library by
  collection, with local progress for visitors, crafted objects, and recipes.
- Replaced the universal 18 px outlined-card theme with the Night Cabinet
  semantic palette, tonal surfaces, bounded role-specific radii, denser type,
  and 48 dp controls.
- Moved collection from the oversized center navigation button into the home
  scene action layer; the bottom bar now contains destinations only.
- Reworked capture as a tonal sensor tray, crafting as a borderless workbench
  list with an object stage, and placement as a scene plus one compact control
  dock. Craft completion now presents the deterministic result artwork.
- Reworked inventory rows as a collection drawer, replaced repeated codex
  question marks with deterministic silhouettes and hints, and organized
  settings into labeled native-density groups.
- User-visible app identity is Locus.
- Capture uses a surroundings/sensor glyph instead of a camera glyph.
- Home, crafting, inventory, and codex object visuals share deterministic
  geometry, weather and capture-time palettes, connector marks, construction
  state, and `visualSeed` detail channels.
- New crafts use the layered `object-v3` visual contract while saved
  `object-v1` and `object-v2` collectibles retain their previous appearance.
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
- Weather capture now retains up to two cataloged atmospheric traces from
  provider-common numeric values and describes them as regional model data.
- Each recipe declares compatible traces. Crafting can keep the base form or
  retain one focus, which deterministically changes its name, layered treatment,
  environment footprint, or connection behavior.
- Existing visitor requirements remain reachable without obtaining a rare
  atmospheric trace.
- Home now prioritizes a taller 5×5 diorama, places the next-visitor goal inside
  the scene, compresses resources into one strip, and removes duplicate summary
  cards.
- The newest persisted visitor remains visible in the scene after the one-time
  arrival dialog closes or the app relaunches.
- The diorama exposes one semantic summary of time, weather, objects, and the
  visible visitor for assistive technologies.

### Assets

- Added 156 collection-expansion runtime sprites covering 18 base objects, 72
  true directional views, 54 construction stages, and 12 visitor portraits,
  plus source atlases, prompts, contact sheet, hashes, and a reproducible
  processor.
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
  layer catalog for the shared compositor.
- Activated those 12 treatments in one alpha-clipped scene/preview compositor;
  this slice adds no new bitmap files.
- Generated art is now used by the home scene, object previews, inventory,
  codex, visitor goal, and material indicators; Canvas rendering remains the
  deterministic fallback.
- Tuned weather/time overlay opacity after simulator review so atmospheric
  pixels do not obscure the daytime neighborhood grid.

### Tests

- Added a deterministic progression test for the complete 28-recipe graph and
  dynamic generated-art coverage for all 18 visitor IDs.
- Added exhaustive placement-catalog tests across every recipe, four rotations,
  all board edges, collision rejection, unsupported directions, art files, and
  iOS-sized movement targets.
- Added exact crafting-art and weather-layer catalog coverage, stage-resolution,
  file-existence, and 48 dp isometric movement tests.
- Added atmospheric catalog thresholds, two-trait ceiling, schema-versioned
  persistence, focus selection, anchor projection, capture propagation, and
  layered-render coverage.
- Added persisted-visitor selection, diorama semantics, and Material list-tile
  regression tests.
- Added a deterministic iOS integration tour covering capture, craft, place,
  inventory, codex, and settings with 14 named full-resolution screenshots.
- Refreshed the complete 14-screen iOS tour after the Night Cabinet redesign;
  the successful route logged no Flutter framework exception or overflow and
  the visual audit found no blocking defect at the tested simulator size.
- Extended the simulator tour with deep-scroll evidence for all three expanded
  codex tabs.
