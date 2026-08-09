# Project status

Last updated: 2026-08-09

## Current state

`main` contains the iOS simulator fixes, deterministic demo isolation, shared
renderer, cataloged pixel-art packages, and a catalog-driven directional
editor. The current working slice closes the stored-object replacement gap and
continues the Pro-reviewed shift from generic Material utility UI toward a
scene-first collection/crafting game shell.

## Completed in the current slice

- Added missing iOS executable metadata and changed user-visible identity from
  Reality Diorama to Locus.
- Changed the native launch background patch to `#071522` to avoid a white
  transition before Flutter paints its first frame.
- Replaced the failing direct SQLite WAL pragma with sqflite's supported
  `setJournalMode('WAL')` helper.
- Made `DEMO_MODE=true` use deterministic steps and capture inputs without
  requesting Bluetooth or Motion permissions on the simulator, and isolated
  demo progress from the production SQLite database.
- Replaced the capture camera glyph; Locus does not use the camera.
- Extracted one deterministic object descriptor/renderer used by the home
  scene, crafting, inventory, and codex. Crafting preview and saved objects now
  share the same `visualSeed` derivation and capture-time palette. New objects
  use `object-v2`; persisted `object-v1` collectibles keep their legacy shape.
- Generated one Pro-model AppIcon candidate and normalized it to an opaque
  1024 × 1024 sRGB PNG. It remains unselected and is not wired into iOS assets.
- Generated, keyed, cropped, and installed 42 production-bound pixel assets:
  10 crafted objects, 6 visitors, 8 scenery pieces, 10 material emblems, and 8
  weather/time overlays.
- Connected the generated art to the home diorama, object previews, inventory,
  codex, visitor goal, and material UI. The deterministic renderer remains the
  construction-state and asset-load fallback.
- Added reproducible prompt/source provenance, an exact manifest with SHA-256
  hashes, and a standard-library validation gate for the generated package.
- Added `placement_catalog.json` as the editor-facing source of truth for four
  directions and independent per-direction asset paths for every recipe.
- Generated two tone-matched source atlases and installed 40 transparent
  quarter-turn sprites: all ten placeable objects × four directions. The tracked
  processor records reviewed crop bounds, exact inventory, RGBA dimensions,
  distinct hashes, and a contact sheet.
- Added selected-footprint highlighting, valid-anchor markers, relevant-edge
  emphasis, catalog previews, direction labels, rotated footprint dimensions,
  and disabled invalid movement/rotation controls to the placement editor.
- Added exhaustive coverage for every recipe across all four rotations, board
  edges, collisions, unsupported rotations, asset existence, and minimum touch
  targets.
- Generated and installed 30 recipe-specific construction sprites: ten recipes
  × foundation/frame/finish. Crafting now previews the expected authored stage
  from available steps, and incomplete inventory/codex objects resolve through
  the same exact crafting-art catalog.
- Generated, processed, and cataloged 12 reusable weather treatments: six
  object-surface patterns and six isometric footprint effects. They are staged
  for the next shared-compositor slice rather than expanding into hundreds of
  complete recipe combinations.
- Replaced the editor's misleading linear movement row with a spatially
  truthful 2×2 isometric direction pad and 48 dp targets. Selectable material
  and object cards now expose selected semantics and visible ink feedback.
- Expanded the placement catalog to include placed, stored, and in-progress
  objects. A stored object can choose a supported direction, preview every
  valid anchor, and return to the first deterministic empty cell without
  bypassing collision or eight-object limits.
- Recorded a dual-agent Pro UI review and an independent Pro asset-system
  review in `docs/UI_GAME_CONCEPT_REVIEW.md`.

## Simulator evidence

Verified on `AppAudit iPhone 16 Pro`, iOS 26.5, UDID
`AF3F5D7C-00EA-4AEE-9268-84BEE844DD61`, using Flutter 3.44.9 and
`--dart-define=DEMO_MODE=true`:

1. install and cold launch;
2. capture opens without Bluetooth/Motion permission alerts;
3. deterministic rain and surroundings material is collected;
4. an alley lamp consumes 1,500 of 4,275 steps and auto-places;
5. the lamp moves one grid cell and commits;
6. force termination and relaunch restore 2,775 steps, the object, and its
   placement.

That baseline simulator run identified missing valid-cell highlighting and
target-visitor condition deltas. The current slice resolves the former in code;
the latter remains planned.

After the shared-renderer and review fixes, the final local gate used Flutter
3.44.9: repository/content/manifest/Swift checks passed, `flutter analyze`
reported no issues, all 38 tests passed, and the Debug iOS simulator build
installed and cold-relaunched successfully. The fresh demo home showed 4,275
steps, and the simulator container contained a separate
`reality_diorama_demo.sqlite3` with its own unspent bucket.

The generated-art slice was then verified with the same pinned SDK: the exact
42-asset manifest passed, `flutter analyze` reported no issues, all 39 tests
passed, and a Debug iOS simulator build installed and launched. The final home
capture shows the generated house, tree, bench, fence, path, atmospheric layer,
and visitor portrait; excessive daytime overlay noise was removed after the
first visual pass.

The catalog replacement slice was verified on the same AppAudit simulator with
its existing demo database left intact. Clear/evening weather plus surroundings
were collected, a 2,400-step bench started at 53% and showed the authored frame
stage in crafting, home, and inventory, and both the completed stairs and the
in-progress bench moved and rotated through validated isometric controls. The
stairs were then returned to storage, selected from the same editor catalog,
rotated from 1×2 to 2×1, placed on a valid empty anchor, and restored as 2/8
placed objects after termination, reinstall, and relaunch. Flutter 3.44.9
repository checks, formatting, analyzer, all 48 tests, and the Debug simulator
build passed; recent Runner logs contained no Flutter exception, RenderFlex, or
overflow report.

## Known risks and gates

- The first production-bound atlas pass is installed, but it still needs final
  composition tuning against a range of populated neighborhoods and text sizes.
- Place plaques and a share-output renderer remain outside this first shared
  renderer slice.
- Visitor scene persistence still depends on transient arrival state rather
  than persisted sightings.
- Direct drag placement and visitor-condition deltas remain future editor
  enhancements; the current catalog-driven button editor validates each move,
  rotation, removal, and replacement commit.
- Weather treatment assets are authored and cataloged but are not drawn yet;
  preview and Flame scene composition must first share one alpha-clipped layer
  resolver so every surface remains deterministic and identical.
- The scene-first home, persisted visitor presence, and a semantic diorama
  summary are the next P1 UI slice from the Pro review.
- Directional art is authoring-complete for the current ten recipes, but a later
  populated-neighborhood visual pass may still tune individual scale/occlusion.
- The AppIcon candidate requires owner review at actual icon sizes before use.
- Wrapper bootstrap remains mutating and must use exactly Flutter 3.44.9; the
  audit machine's global SDK was 3.44.1.
- WeatherKit provisioning, signing, Store products, physical-device permission
  behavior, accessibility, battery, and thermal checks remain release gates.
