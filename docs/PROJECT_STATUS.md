# Project status

Last updated: 2026-08-09

## Current state

`main` contains the iOS simulator fixes, deterministic demo isolation, shared
renderer, cataloged pixel-art packages, and a catalog-driven directional
editor. The current working slice makes the home surface scene-first, keeps the
latest persisted visitor visible after its one-time arrival dialog, adds a
semantic scene summary, and establishes a repeatable iOS screenshot tour for
the complete deterministic demo loop. The active UI migration now uses the
Night Cabinet semantic palette and removes the global outlined-card treatment;
collection is a scene action rather than an oversized navigation item.

## Completed in the current slice

- Added semantic canvas, scene, panel, text, action, reward, weather, visitor,
  danger, and focus tokens with verified text/action contrast.
- Replaced the default 18 px outlined `PixelCard` with tonal 10 px surfaces;
  selected cards retain an explicit mint outline.
- Reduced the bottom bar to three destinations and moved the labeled,
  ready-count-aware collection action into the home diorama.
- Differentiated the core-loop surfaces: capture uses sensor readouts, recipes
  use divider-based rows, crafting uses one object stage, and placement uses a
  borderless scene with compact tile and control docks.
- Added the crafted object preview to the completion confirmation so the reward
  is recognizable without adding ornamental choreography.
- Converted material, crafted-object, and recipe lists to divider-based rows;
  kept record and codex tiles only where visual comparison is the real task.
- Replaced identical undiscovered codex glyphs with muted silhouettes derived
  from the shipping visitor and deterministic object renderers.
- Reorganized settings into explicit grouped sections and removed action mint
  from passive privacy and sensor information.
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
- Added `atmospheric_traits.json` as the source of truth for six
  provider-neutral traces, numeric thresholds, priority, Korean copy, spread,
  environment effects, and visual-strength modifiers. Each capture keeps at
  most two.
- Added schema-v2 migration columns so classified traces survive weather
  consumption while each `object-v3` craft stores only one optional,
  user-selected focus and stable variant key. Previous materials and objects
  keep their prior visual contract.
- Turned the 12 staged weather assets into one alpha-clipped compositor used by
  the home scene, crafting, inventory, codex, and placement preview. No new
  bitmap was required for this slice.
- Added capture and crafting copy that identifies the provider result as a
  regional weather model rather than an exact on-site measurement.
- Added recipe-specific trait affinities, a base-or-focus choice in crafting,
  anchor-based environment effects, strong-wind connection range, and a
  low-visibility quiet-zone override without changing visitor reachability.
- Moved the visitor goal into the diorama frame, compressed steps and capture
  readiness into one header strip, enlarged the scene, and removed the two
  dashboard-style summary cards from home.
- Derived the scene visitor from the newest persisted sighting while retaining
  the new-visitor ID only for the one-time arrival dialog.
- Added one VoiceOver image summary for the 5×5 scene with time, weather,
  placed-object names, and the currently visible visitor.
- Rebuilt `PixelCard` on an opaque Material surface so nested adaptive list
  controls paint selection and ink feedback without a hidden-splash assertion.
- Added an iOS integration tour that resets only the isolated demo database,
  collects weather and surroundings, crafts and places one object, traverses
  every primary tab and settings screen, and exports named PNG evidence.

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

The atmospheric-focus slice was then built from a temporary platform-wrapper
recovery checkout and installed on the existing AppAudit simulator without
creating another device. Demo capture exposed `Demo 지역 모델`, the `짙은 구름`
trace, and its bounded effect copy; the planter recipe offered `기본 형태` or
`짙은 구름`, and selecting it updated the preview name to `구름빛 화분` with no
visible overflow. The installed local Flutter was 3.44.1 rather than the pinned
3.44.9. Repository/content/manifest/Swift checks and analyzer passed. The full
test run found one incorrect comparison cell in the new diagonal-spread test;
after correcting only that assertion, the focused five-test diorama rule file
passed. The Debug iOS simulator build, install, and launch all succeeded.

The scene-first and screenshot-tour slice was verified on the same shared
`AppAudit iPhone 16 Pro` with Flutter 3.44.1. The current checkout intentionally
lacks generated `Runner.xcodeproj`, so the iOS build and `flutter drive` run
used a temporary wrapper-recovery copy. The deterministic integration tour
completed in 35 seconds with all tests passed and exported 14 full-resolution
1206×2622 PNGs plus a labeled contact sheet under
`artifacts/ui-screenshots/2026-08-09-final/`. The successful run logged no
Flutter exception or overflow. Analyzer and the full local unit/widget suite
also passed. The required Android demo debug APK built successfully from the
same temporary wrapper-recovery copy.

## Known risks and gates

- The first production-bound atlas pass is installed, but it still needs final
  composition tuning against a range of populated neighborhoods and text sizes.
- Place plaques and a share-output renderer remain outside this first shared
  renderer slice.
- Direct drag placement and visitor-condition deltas remain future editor
  enhancements; the current catalog-driven button editor validates each move,
  rotation, removal, and replacement commit.
- Atmospheric thresholds are initial balance values and need product telemetry
  or structured playtest evidence before expanding providers or adding more
  traits.
- The scene-first home, persisted visitor presence, and a semantic diorama
  summary are the next P1 UI slice from the Pro review.
- Directional art is authoring-complete for the current ten recipes, but a later
  populated-neighborhood visual pass may still tune individual scale/occlusion.
- The AppIcon candidate requires owner review at actual icon sizes before use.
- Wrapper bootstrap remains mutating and must use exactly Flutter 3.44.9; the
  audit machine's global SDK was 3.44.1.
- WeatherKit provisioning, signing, Store products, physical-device permission
  behavior, accessibility, battery, and thermal checks remain release gates.
