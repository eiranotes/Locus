# Changelog

## Unreleased

### Fixed

- Capture-history records no longer display placement scenery as if it were the
  collected result; linked surroundings effects now remain visually distinct
  from objects that can be placed in the diorama.
- Static full-screen weather/time textures no longer appear as unexplained
  falling streaks or translucent blocks over the neighborhood.
- Capture history no longer silently stops at the latest 100 records; older
  entries can be loaded in stable 24-record pages with an exact total.
- Temporarily unreachable later-layer visitors no longer appear as active home
  goals or arrival candidates before their prerequisite recipe is unlocked.

- Cold launch, app resume, capture, and construction completion now refresh
  readiness and visitor eligibility in a consistent order.
- Satisfied unseen visitors can no longer be preempted by a repeat-ready entry
  earlier in catalog order; the shown target and actual arrival use one policy.
- Passive app refresh no longer risks asking for location permission outside
  the focused capture flow.
- Visitor codex copy no longer claims that the 18-entry catalog has four
  records.

- Visitor goals no longer expose internal English object, tag, weather, or time
  identifiers in Korean UI.
- Capture-result material art is precached and shows a glyph until the first
  decoded asset frame is ready instead of capturing a blank orb.
- Repeated locked recipe rows are collapsed into one undiscovered count per
  collection, and visitor arrival names the recipe it unlocked.
- Android launch-background XML now wraps its navy color in a valid rectangle
  drawable, allowing AAPT resource linking to complete.

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
- Inventory header counts now follow the active 기록, 재료, or 만든 것 tab
  instead of always reporting capture records.
- Visible step quantities now use consistent thousands separators across home,
  capture, crafting, inventory, codex, and settings.
- Prototype version text is now debug-only and cannot appear in a release UI.

### Changed

- Capture-history cards now show the record's linked surroundings material as a
  framed effect sample. Weather-only records use their weather material and
  unlinked legacy records use a neutral trace without fabricating context.
- Rain now moves through an eight-frame 8 fps pixel cycle. Reduced-motion mode
  omits falling drops, and no new token, bitmap, or dependency was added.
- Home, capture, crafting, inventory, codex, placement, and settings copy is
  shorter and avoids repeating visible state or the same next action. Privacy,
  regional-weather-model, provider, recovery, and accessibility wording stays
  explicit.

- The 28-recipe collection now unfolds through deterministic 10/7/7/4 layers
  instead of placing nearly every visitor reward directly after the initial
  catalog. Later codex entries name their missing prerequisite recipe.
- Record inventory uses an explicit pixel-style `이전 기록 더 보기` action and
  a one-column fallback for narrow widths or large text.

- Time and representative-weather patterns now appear as non-consuming visitor
  clues on home, capture results, inventory, and codex surfaces.
- Capture results distinguish new and repeated pattern occurrences and name
  the current target visitor when the capture contains a matching clue.
- Repeat visitor encounters now append a coarse scene-memory row in SQLite v4;
  the codex shows total visits and the latest weather/time context.
- Home shows repeat cooldown wait text, visitor first-meeting rewards, and
  action-oriented pattern hints. Placement feedback names conditions completed
  by the proposed drop.

- Captures now produce separately collectible time, season, weather, and
  aggregate-surroundings patterns. When multiple inputs arrive together, up to
  six weather, surroundings, time, and full-scene combinations are stored as
  their own collectible patterns.
- Capture results summarize individual pattern categories and show only two
  representative simultaneous combinations. Inventory adds a `패턴` subtab
  with three expandable individual groups, fixed short combination titles,
  concise component summaries, and repeat collection counts without new design
  tokens or assets.
- Pattern surfaces now use shared non-antialiased pixel stamps, family marks,
  component-derived two/three-input weave marks, stepped disclosure carets,
  and terminal-ended ledger rules instead of generic Material glyphs. Korean
  body typography and the existing token inventory are unchanged.
- High-frequency actions, cards, scene frames, dialogs, and placement controls
  now use a cut-corner pixel-game grammar with pressed feedback. The existing
  design-token inventory is unchanged.
- Placed objects can be dragged directly across the diorama with live
  valid/invalid previews and commit-on-release behavior. Stored objects can be
  long-pressed from the catalog and dropped onto a chosen valid cell.
- Placement previews now show the target visitor's before/after condition
  count while reusing the production rule engines.
- Recipe browsing now retains available steps and the selected capture
  materials; the craft cost and primary action remain visible in a
  safe-area-aware bottom region on standard screens and fall back inline for
  compact or large-text layouts.
- Craft completion now offers `내 공간 보기`, capture deferral says
  `나중에 만들기`, and home copy states that surroundings are optional.
- Placement direction controls are labeled `미세 조정` and rotation is
  separated as `방향 바꾸기`, making direct object dragging the clear primary
  interaction without removing accessible 48 dp alternatives.

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

- Added 50 distinct generated RGBA assets: 20 terrain details, 10 weather/time
  details, 10 placement-editor markers, and 10 action emblems, with five source
  atlases, prompts, contact sheet, hashes, and a reproducible processor.

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

- Added actionable-visitor policy and exact 10/7/7/4 progression-layer tests.
  The iOS tour now seeds 30 historical captures, verifies 24-of-31 paging and
  the final seven-record load, and exports both pagination states.
- Added visitor priority, repeat fairness, passive-permission, pattern-evidence,
  and scene-memory serialization coverage.

- Added deterministic pattern-engine coverage for both collection channels,
  channel-specific failure paths, exact individual/combination counts,
  component provenance, serialization round trips, short presentation titles,
  representative selection, and compact labels. The iOS UI tour captures the
  result summary, collapsed individual groups, expanded-group behavior, and
  concise combination inventory.
- Added painter-level distinction checks for two-input, three-input,
  same-family, and mixed-family pixel marks. The iOS tour now exports a named
  expanded-weather-group screenshot alongside the pattern summary and full
  combination ledger.
- Added isometric viewport/cell projection round trips, Korean visitor-target
  labels, exact 50-asset inventory/hash coverage, and pixel direction-control
  regression coverage.

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
