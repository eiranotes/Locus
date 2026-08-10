# Project status

Last updated: 2026-08-10

## Current state

`main` contains the iOS simulator fixes, deterministic demo isolation, shared
renderer, cataloged pixel-art packages, and a catalog-driven directional
editor. The current working slice replaces generic rounded controls with
cut-corner pixel-game surfaces without adding design tokens, adds direct
drag-to-cell placement and target-visitor deltas, and installs 50 new generated
scene/UI assets. It now also keeps selected capture materials and available
steps visible through the crafting list, promotes the craft action into a
safe-area-aware bottom region, and makes direction buttons an explicitly
labeled fine-adjustment fallback to direct dragging. The home surface remains
scene-first, the latest persisted visitor remains visible after its one-time
arrival dialog, and collection stays a scene action rather than an oversized
navigation item. Captures now also retain separate time, season, weather, and
surroundings patterns plus a bounded set of simultaneous-input combinations;
the capture result and a dedicated inventory subtab distinguish the two. Those
surfaces now use state-derived pixel marks, stepped disclosure carets, and
terminal-ended ledger rules instead of generic Material network/category
icons.
The retention P0 slice now makes every return path converge on the same world
refresh order, aligns the visible visitor target with actual arrival priority,
uses time/weather patterns as non-consuming visitor evidence, and accumulates
repeat visits as coarse scene memories rather than overwriting the only record.
The follow-up retention slice now unfolds the 28-recipe library across three
post-initial progression layers and pages the permanent capture ledger instead
of silently hiding everything older than the latest 100 records. Capture
history now presents each row as a deterministic pixel postcard assembled from
the record's time, season, weather, surroundings, and stable ID. Visible copy
across home, capture, crafting, inventory, codex, placement, and settings has
also been distilled so state and next action are not explained twice.

## Completed in the current slice

- Replaced the repeated generic record stamp with a deterministic scene preview
  that composes existing scenery, terrain, time, weather, atmosphere, and
  optional-surroundings art. No new token or bitmap asset was added.
- Removed repeated instructional prose from primary loop surfaces while keeping
  provider attribution, regional-model limits, sensor non-identification,
  recoverable error copy, and accessibility semantics explicit.

- Rebalanced the recipe unlock graph from a nearly flat expansion into 10
  initial recipes followed by deterministic layers of 7, 7, and 4 recipes.
  Explicit object prerequisites stay within three visible visitor conditions.
- Added a domain progression policy so home goals and arrivals include only
  visitors whose explicit object/tag requirements can be attempted with the
  currently unlocked recipe library. The codex names a missing prerequisite
  recipe instead of presenting a temporarily impossible hint as an active goal.
- Replaced the capture ledger's fixed latest-100 query with stable 24-record
  pages and an exact total count. Inventory shows total versus loaded records,
  uses an explicit 48 dp pixel `이전 기록 더 보기` action, and falls back to a
  roomier one-column record grid on narrow or large-text layouts.

- Added one world-refresh path for cold launch, resume, pull-to-refresh, capture,
  and construction-related step updates. Passive refresh never requests a new
  location permission; the capture sheet keeps that contextual responsibility.
- Added deterministic visitor priority shared by target and resolution:
  satisfied unseen visitors first, then oldest eligible repeats after the
  six-hour cooldown. Home shows repeat wait time and placement names newly
  completed conditions.
- Linked collected time/weather patterns to matching visitor requirements as
  presentation evidence only. Capture results show new/repeated counts and
  target relation; inventory and codex expose the same non-consuming clues.
- Added SQLite schema v4 `visitor_encounters`, backfilled legacy sightings, and
  grouped visit counts. The codex now shows repeat count and latest coarse
  weather/time context without loading an unbounded encounter history.

- Added deterministic collection-pattern classification for time, season,
  weather kind and numeric bands, surroundings kind and aggregate signal bands.
- Added up to six separately collectible simultaneous-input combinations per
  capture, including within-channel weaves and weather/time/surroundings cross
  patterns. Only derived keys, labels, strength, and component provenance are
  persisted; raw Bluetooth observations remain outside application storage.
- Added schema-v3 `collected_patterns` persistence in the same transaction as
  its capture/material rows, controller reload support, a pattern summary on
  the capture result, and separate `개별 패턴` / `동시 수집 조합` inventory
  sections without adding design tokens or bitmap assets.
- Replaced the capture-result tag cloud and long generated combination titles
  with category counts, two representative combinations, and fixed short
  titles. Inventory now collapses individual patterns into three disclosure
  groups and presents all combinations as divider rows inside one pixel panel.
- Replaced pattern-surface Material glyphs with one shared 10×10-grid painter:
  two- and three-input combinations expose their actual time, weather, and
  surroundings families; same-family weaves remain distinct; disclosure and
  divider states use hard-edged pixel geometry. System Korean text and the
  existing Night Cabinet tokens remain unchanged.
- Kept the capture-to-craft context visible in the recipe list, made the craft
  action persistently reachable on standard-height screens, and retained an
  inline scrolling fallback for compact or large-text layouts.
- Changed craft completion from a generic confirmation into `내 공간 보기`,
  changed capture deferral to `나중에 만들기`, and clarified the optional
  status of surroundings in the home loop copy.
- Made the inventory header count follow its active tab and standardized
  thousands separators for visible step quantities without a new dependency.
- Labeled direction controls as `미세 조정`, preserved 48 dp targets, and kept
  direct object dragging as the primary placement interaction.
- Restricted the prototype version footer to debug builds while preserving the
  explicit demo/production data-mode status block.
- Added direct manipulation for placed objects with grab-offset preservation,
  live valid/invalid cell previews, commit-on-release persistence, and cancel
  behavior that leaves the saved placement unchanged.
- Added long-press drag from the crafted-object catalog onto the board while
  keeping the explicit first-empty-cell action and 48 dp direction pad as
  accessible alternatives.
- Added live target-visitor condition counts during valid placement previews;
  all preview calculations reuse the production environment, connection, and
  visitor engines.
- Generated, keyed, cropped, and installed 50 distinct RGBA assets: 20 terrain
  details, 10 weather/time details, 10 editor markers, and 10 action emblems.
  The runtime now contains 330 PNG files with 312 distinct payload hashes.
- Replaced high-frequency generic Material buttons and smooth card/dialog
  corners with pressed cut-corner pixel controls using the existing palette;
  no color, spacing, or radius token was added.
- Localized visitor requirement targets so raw ids such as `fountain`, `stay`,
  `night`, and `clear` no longer leak into Korean UI.
- Precached capture-result material art and kept a meaningful glyph visible
  until the first asset frame arrives.
- Collapsed repeated locked recipe rows into one per-collection undiscovered
  summary and made the visitor arrival dialog name its unlocked recipe.

- Expanded the collectible catalog from 10 to 28 placeable objects and from 6
  to 18 visitors across `골목 생활`, `정원 생태`, and `밤의 장터` sets.
- Added six immediately craftable expansion recipes and twelve visitor-reward
  recipes, with an automated progression check proving that every locked
  recipe remains reachable from the initial catalog.
- Generated and installed 156 production runtime sprites: 18 object bases, 72
  authored quarter-turns, 54 construction stages, and 12 visitor portraits.
- Kept the 5×5 board and eight-active-object limit; retention comes from
  collecting, swapping, and recomposing a larger library rather than crowding
  the diorama or monetizing progression inputs.
- Reworked all three codex tabs around a visible overall completion measure and
  collection sections, so 18 visitors and 28 recipes remain scannable without
  adding ornamental filters, badges, or dashboard cards.
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
- Extended the tour with deep-scroll captures for the expanded visitor,
  crafted-object, and recipe collection sections.

## Collection-pattern verification

Verified on 2026-08-10 with Flutter 3.44.1:

- `flutter analyze` passed with no issues;
- all 80 Dart/Flutter unit and widget tests passed;
- `./tool/validate.sh` passed repository, content, manifest, Swift parse,
  formatting, analysis, and test gates;
- the required Android demo debug APK built successfully;
- an iOS integration test downgraded an isolated demo database to schema v2,
  reopened it through the v3 migration, transactionally saved ten derived
  patterns with a capture, and restored all ten after another reopen;
- the deterministic iOS demo tour passed on `LocusPlacementQA` and exported 21
  full-resolution PNGs, including the capture pattern summary, individual
  pattern inventory, and simultaneous-combination inventory.

The iOS wrapper was regenerated only in a temporary recovery copy. Simulator
screens prove deterministic app behavior, not physical Bluetooth or live
WeatherKit behavior.

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

The Night Cabinet redesign was then verified from a fresh temporary
wrapper-recovery checkout at the same committed revision. The first tour found
one Material ancestry assertion in the capture surroundings switch; replacing
the tonal `DecoratedBox` with `Material` preserved the design and removed the
runtime fault. The repeated deterministic tour completed in 36 seconds with
all tests passed and refreshed 14 full-resolution 1206×2622 PNGs plus a labeled
contact sheet under `artifacts/ui-screenshots/2026-08-09-night-cabinet/`.
Screen-by-screen inspection found no clipped content, overflow, hidden ink, or
remaining floating-center action at the tested size. The Android demo debug APK
also built successfully from that revision with Flutter 3.44.1.

The pixel-control and direct-manipulation slice was verified on the existing
`LocusPlacementQA` simulator. The final deterministic tour completed in 42
seconds with all tests passed and exported 17 full-resolution screenshots plus
a contact sheet under
`artifacts/ui-screenshots/2026-08-10-pixel-drag/`. The tour dragged the first
placed object from cell (0, 0) to (1, 0) and asserted the persisted snapshot,
while the screenshot pass confirmed visible capture-result art, readable Korean
visitor requirements, aggregate locked-recipe summaries, and no overflow on the
inspected surfaces. `./tool/validate.sh` passed repository/content/Swift checks,
analyzer, and all 66 tests. The required demo Android debug APK also built
successfully after correcting the launch background's invalid direct hex
drawable reference.

The core-loop UI refinement was verified on the same `LocusPlacementQA`
simulator from a temporary platform-wrapper recovery copy. The deterministic
tour passed and exported 17 full-resolution 1206×2622 PNGs plus an inspected
contact sheet under
`artifacts/ui-screenshots/2026-08-10-ui-loop-refinement/`. The pass confirmed
capture-selected material context in the recipe list, an unobscured bottom
craft action, the outcome-specific completion action, labeled placement fine
adjustment, and active-tab inventory counts. `./tool/validate.sh` passed
repository/content/manifest/Swift checks, analyzer, and all 67 tests. The first
Android build attempt exposed one missing file in the host's global Gradle
transform cache; the identical required demo APK build then passed with a fresh
isolated `GRADLE_USER_HOME`, producing `build/app/outputs/flutter-apk/app-debug.apk`.

The pixel-pattern UI pass was verified from a temporary platform-wrapper
recovery copy on the same `LocusPlacementQA` simulator with the host's Flutter
3.44.1. The schema-v2-to-v3 migration and complete deterministic demo tour
passed and exported 21 full-resolution screenshots under
`artifacts/ui-screenshots/2026-08-10-pixel-pattern-ui/`. The inspected capture,
collapsed inventory, expanded weather group, and complete combination ledger
show distinct code-rendered marks without clipped text or overflow. The
repository checkout retained its intentionally omitted iOS wrapper files.

The retention P0 slice was verified on 2026-08-10 with Flutter 3.44.1.
`./tool/validate.sh` passed repository, content, manifest, Swift parse,
formatting, analyzer, and all 86 unit/widget tests. The required Android demo
debug APK built successfully. The first iOS migration run exposed that a
partially upgraded database could already contain `visitor_encounters`; making
schema-v4 table/index creation idempotent fixed that recovery case. A fresh
temporary wrapper-recovery copy then passed the schema-v2-to-v4 migration and
the complete 48-second deterministic tour on `LocusPlacementQA`, exporting 21
full-resolution screenshots under
`artifacts/ui-screenshots/2026-08-10-retention-p0/`. Visual inspection of home,
capture patterns, expanded inventory, placement, and both codex scroll states
found no clipped text or overflow at the tested simulator size. The temporary
wrapper copies were deleted; the repository's intentionally omitted iOS
project remained unchanged.

The progression/pagination follow-up was verified on 2026-08-10 with Flutter
3.44.1. `./tool/validate.sh` passed repository/content/manifest checks, Swift
parse, formatting, analyzer, and all 89 unit/widget tests. The required Android
demo debug APK built successfully. A temporary iOS wrapper-recovery copy passed
the schema-v2-to-v4 migration and the 57-second deterministic drive. The tour
seeded 30 historical records, made one current capture, proved the first 24 of
31 records plus the explicit seven-record continuation, and exported 23
full-resolution screenshots under
`artifacts/ui-screenshots/2026-08-10-retention-p1/`. Visual inspection of the
load-more states and deeper visitor cards found no clipped text or overflow.
The temporary wrapper copy was deleted after export; tracked wrapper policy was
unchanged.

The record-postcard and copy-distillation slice was verified on 2026-08-10 with
Flutter 3.44.1. `./tool/validate.sh` passed repository/content/manifest checks,
Swift parse, formatting, analyzer, and all 92 unit/widget tests. The required
Android demo debug APK built successfully. A temporary iOS wrapper-recovery copy
passed the schema-v2-to-v4 migration and complete deterministic tour twice on
`LocusPlacementQA`, exporting 23 full-resolution screenshots under
`artifacts/ui-screenshots/2026-08-10-record-postcards/`. Visual inspection
confirmed distinct scenery across paged historical records, weather and
surroundings treatment on the current record, concise copy without clipping on
the edited screens, and no overflow. The temporary wrapper copy was deleted;
the repository's intentionally omitted iOS project remained unchanged.

## Known risks and gates

- The first production-bound atlas pass is installed, but it still needs final
  composition tuning against a range of populated neighborhoods and text sizes.
- Place plaques and a share-output renderer remain outside this first shared
  renderer slice.
- Direct drag is implemented and unit-tested at the projection/validation
  boundary; touch feel, cancellation, and large-text behavior still require a
  physical-device accessibility pass.
- Atmospheric thresholds are initial balance values and need product telemetry
  or structured playtest evidence before expanding providers or adding more
  traits.
- Visitor encounter counts, coarse contexts, and the deeper 10/7/7/4 unlock
  graph are now implemented, but D7/D30 value and layer pacing still need
  longitudinal beta or structured playtest evidence.
- Directional art is authoring-complete for the current ten recipes, but a later
  populated-neighborhood visual pass may still tune individual scale/occlusion.
- The AppIcon candidate requires owner review at actual icon sizes before use.
- Wrapper bootstrap remains mutating and must use exactly Flutter 3.44.9; the
  audit machine's global SDK was 3.44.1.
- WeatherKit provisioning, signing, Store products, physical-device permission
  behavior, accessibility, battery, and thermal checks remain release gates.
