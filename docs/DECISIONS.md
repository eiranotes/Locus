# Decisions

## 2026-08-10

### One capture can yield individual and simultaneous-combination patterns

A successful capture no longer collapses all available context into only one
weather material and one optional surroundings material. A deterministic
`collection-patterns-v1` engine derives individually collectible time, season,
weather-kind, normalized weather-band, surroundings-kind, and aggregate
surroundings-band patterns. The same capture may also yield at most six
separately collectible combinations: weather weave, surroundings weave,
weather/time, surroundings/time, weather/surroundings, and the full
weather/time/surroundings scene.

SQLite schema v3 stores each occurrence by capture and pattern key in the same
transaction as its capture and material rows. Stored component keys explain
which derived patterns formed a combination, but raw Bluetooth identifiers,
names, addresses, advertisements, or observations are never persisted. The UI
adds a `패턴` subtab inside the existing inventory instead of a new top-level
destination. The capture result does not expose the engine's full tag set: it
shows category counts and at most two representative combinations. Inventory
groups individual patterns into `시간과 계절`, `날씨`, and `주변` disclosure
rows, while combination values use fixed short type titles and a separate
component summary. One cut-corner panel contains each collection section so
repeated borders do not become the hierarchy. This slice uses the existing
Night Cabinet tokens and adds no visual token, bitmap asset, permission,
provider, or dependency. A shared non-antialiased 10×10-grid painter replaces
generic network, category, and disclosure glyphs on pattern surfaces. The
combination mark derives fixed source positions and colors from persisted
component families, so weather/time/surroundings and same-family weaves remain
visually distinct without parsing presentation strings inside screen widgets.
Native Korean typography is retained for legibility.

### Core-loop refinement changes hierarchy without adding visual tokens

The existing Night Cabinet palette, system font, cut-corner `PixelButton`, and
48 dp control size remain unchanged. Capture-selected weather and optional
surroundings stay visible on the recipe list, while the craft cost and action
occupy a safe-area-aware bottom region on standard-height screens. Compact
screens and text scales above 130% keep the same action inline in the scroll
flow so content is never covered.

Direct board dragging remains the primary placement interaction. The direction
pad is retained for accessibility and exact cell movement but is labeled
`미세 조정`; rotation is separated as `방향 바꾸기`. Inventory counts describe
the active tab, generic completion and deferral labels are replaced with their
actual outcomes, and prototype version text is compiled into debug UI only.
No new color, spacing, radius, typography token, font, asset, or dependency is
introduced by this refinement.

### Pixel-game UI polish changes components, not the token inventory

The existing Night Cabinet colors remain the source of truth. This slice adds
no color, spacing, typography, or radius token. High-frequency actions instead
use one cut-corner, two-pixel-border control with a two-pixel pressed offset;
cards, dialogs, scene frames, and direction controls use the same hard-edged
shape grammar. Native text and Material semantics remain intact, and all
interactive targets stay at least 48 dp.

### Direct placement separates preview state from persisted state

The Flutter/Flame boundary shares one reversible 360-unit isometric projection.
A board drag preserves the pointer-to-object-anchor offset, updates only an
editor-overlay `Placement`, and calls `placeOrMoveObject` once on a valid
release. Invalid or cancelled drags discard the overlay. A long press on the
catalog supports placing stored objects onto an explicit cell; the deterministic
first-empty-cell button and direction pad remain keyboard/screen-reader-safe
fallbacks. Preview visitor counts rebuild through the same environment,
connection, and visitor engines used by a committed placement.

### The 50-piece art addition is bounded by runtime roles

The added ImageGen package contains exactly 20 terrain details, 10 atmosphere
details, 10 editor markers, and 10 action emblems. Sources use the existing
Locus contact sheets as strict style references and a removable magenta key.
The processor produces distinct RGBA files and records dimensions, source cell,
and SHA-256 for every output. These are ambient and interaction assets, so they
do not expand the recipe catalog, visitor graph, 5×5 board, or eight-object
active limit.

## 2026-08-09

### Night Cabinet replaces the universal outlined-card grammar

The shell uses a quieter semantic palette so authored diorama art remains the
most memorable surface. Canvas, scene, panel, raised, text, action, reward,
weather, visitor, danger, and focus colors now have distinct roles. Mint is
reserved for the primary action and current selection rather than also serving
as success, progress, navigation, and decoration.

Default panels are separated by tone rather than an outline. Scene, tray,
card, tile, chip, and control radii are independently bounded; full pills are
reserved for compact status. The foreground collection action moves out of the
bottom navigation and into the home scene action layer. The bottom bar contains
destinations only.

### Core-loop surfaces use distinct physical metaphors

Capture is a raised sensor tray with separate weather and optional-surroundings
readouts. Crafting uses borderless recipe rows and one scene-like object stage;
material pickers remain compact selectable tiles because comparison is their
purpose. Placement keeps the board in one scene viewport and groups selected
object controls in a single raised dock. Completion shows the deterministic
crafted object rather than a text-only confirmation.

### Secondary collections are a drawer, field guide, and grouped settings

Inventory uses divider-based material and object rows with scene-backed art
tiles; record stamps remain a compact visual grid because their captured
conditions are the comparison target. Codex tiles use silhouettes from the
real deterministic visitor/object assets instead of repeated question-mark or
lock illustrations. Recipe entries are borderless field-guide rows. Settings
uses labeled native-density groups, with accent color removed from passive
informational icons.

### Home is scene-first and the scene visitor is persisted

The home header uses one compact resource strip and the visitor goal sits
inside the diorama frame. The two dashboard summary cards are removed so the
5×5 neighborhood remains the dominant first-screen surface.

`newVisitorId` remains transient and controls only the one-time arrival dialog.
The scene resolves its visible visitor from that arrival first, otherwise from
the persisted sighting with the newest `lastSeenAt`. A deterministic visitor-ID
tie break prevents database order from changing the result. The diorama exposes
one semantic image label containing time, regional weather kind, placed-object
names, and the visible visitor; individual canvas pixels are not separate
accessibility nodes.

### Screenshot QA uses the isolated deterministic demo database

The integration tour deletes only `reality_diorama_demo.sqlite3`, never the
production database. It then exercises capture, crafting, placement, inventory,
codex, and settings in one iOS run and sends named screenshots to a host driver.
Generated platform wrappers stay in a temporary recovery copy when the tracked
checkout intentionally omits `Runner.xcodeproj`.

### Product identity is Locus

User-visible runtime strings, iOS bundle display/name metadata, and the native
launch transition use Locus. Existing internal package names and the bundle ID
remain unchanged in this slice to avoid an unrequested storage/provisioning
migration.

### Simulator checks use deterministic demo gateways

`DEMO_MODE=true` is the supported offline simulator path. It uses deterministic
weather, location, surroundings, and steps, and must not ask for real Bluetooth
or Motion permissions. Production gateways and in-context permission timing are
unchanged. Demo state is stored in `reality_diorama_demo.sqlite3`, separate from
the production database, so synthetic materials and steps cannot leak into a
normal launch.

### SQLite WAL uses the package API

Database startup calls `Database.setJournalMode('WAL')`. Executing the pragma
directly during sqflite `onConfigure` failed on the audited iOS simulator.

### Object visuals have one deterministic contract

Home, crafting, inventory, and codex use `ObjectVisualDescriptor` and
`DeterministicObjectRenderer`. Seeded variations use named stable-seed channels
and remain inside fixed placement silhouettes. Capture time selects a palette;
crafting preview and the created object share one seed function. New objects use
`object-v2`, while `object-v1` bypasses new detail channels to preserve existing
collectibles.

### Collection depth expands the library, not the active board

The retention-facing catalog now contains 28 deterministic recipes and 18
visitors, organized as the original first neighborhood plus `골목 생활`,
`정원 생태`, and `밤의 장터`. The 5×5 board and eight-active-object ceiling stay
fixed. Players build variety by collecting, storing, swapping, and recomposing
objects; the scene does not become a dense inventory dump.

Six expansion recipes are initially available and twelve are deterministic
visitor rewards. Every visitor exposes no more than three visible conditions,
and an iterative content test must prove that explicit object/tag dependencies
can be reached from the initial catalog. The same generated object identity is
used for base preview, construction stages, all four placement directions, and
the shared renderer fallback contract.

Generated-art packs may coexist in the installed runtime directory. Each pack
validator owns and hashes only its declared inventory, while the placement and
crafting catalogs remain the exact cross-pack coverage gate.

The codex presents one overall completion line per tab, then groups entries by
collection with a small local count. This keeps the larger library legible while
avoiding a second navigation system, dense filter chips, achievement badges, or
generic dashboard cards. Undiscovered entries keep recognizable silhouettes;
their exact identity remains hidden until the corresponding discovery.

### Generated static art is now the primary renderer input

The owner explicitly approved moving beyond prototype geometry. A fixed v1
package of 42 generated sprites now supplies crafted objects, visitors, fixed
scenery, material emblems, and weather/time effects. Generation happens only at
authoring time: sources, exact prompts, crop rules, output dimensions, alpha
contract, and SHA-256 hashes are tracked. Locus never generates artwork at
runtime. Deterministic Canvas geometry remains available for construction state
and asset-load failure, preventing saved objects from becoming unreadable.

The AppIcon remains a separate review candidate outside `AppIcon.appiconset`.
Launch continues to use a solid native background rather than generated splash
art.

### Application dependencies are locked

Locus is an application rather than a reusable Dart package, so the generated
`pubspec.lock` is retained to keep local and CI package resolution reproducible
with Flutter 3.44.9.

### Placement presentation is catalog-driven

`assets/content/placement_catalog.json` is the editor-facing contract for every
recipe's four directions and directional art. Gameplay dimensions and effects
remain in `recipes.json`; the placement catalog must cover the recipe set
exactly once. Each direction points to an independent production PNG from the
40-asset directional package. The four views are authored quarter-turn redraws,
not runtime mirrors, so asymmetric openings, backs, signs, and approaches remain
spatially truthful. Source atlases, reviewed row bounds, contact sheet, alpha
processing, and hashes are retained as a reproducible authoring contract.

Board selection fills and connection emphasis remain code-rendered while the
new generated editor markers reinforce valid, selected, invalid, grab, drop,
direction, and rotation states. They are interaction feedback rather than
collectible art and must scale cleanly with layout and accessibility.

All editor actions query the same `PlacementEngine` validation used by commits.
Invalid moves and rotations are disabled before mutation, selected footprints
and valid anchors are visible on the board, and only connections involving the
selected object remain emphasized. Direct drag now uses the same validation and
commit API; its coordinate, cancellation, preview, and fallback contracts are
recorded in the 2026-08-10 decision above.

The editor catalog includes every crafted object, not only rows already present
in the placements table. Stored or temporarily unplaced construction objects
remain selectable, may preview any catalog-supported direction, and are written
back only after a valid long-press drop or the explicit empty-cell placement
action. The fallback first cell is deterministic row-major order; normal
collision, footprint, and active-object-limit validation remains authoritative.

### Combination art is layered, not exhaustively baked

Crafted visuals do not receive one bitmap per recipe × weather × surroundings ×
time × direction combination. That would create 300 craft combinations and up
to 3,600 placed states before seeded details. Recipe identity remains in the 40
directional completed sprites. Ten recipes each receive three bounded authored
construction stages through `crafting_art_catalog.json`.

Weather identity is a shared 12-asset layer set registered in
`visual_layer_catalog.json`: six surface patterns and six isometric footprint
effects. Time palette, surroundings connectors, and seeded details remain
runtime treatments. Place plaques remain native/code-rendered so Korean labels
are not baked into images. Preview and scene composition now share one
alpha-clipped layer resolver for these assets.

### Editor movement follows the visible isometric axes

The 5×5 logical grid remains unchanged, but movement controls now use northwest,
northeast, southwest, and southeast arrows in a 2×2 pad. This matches the
screen-space result of the two logical grid axes. Targets are 48 dp so the same
control clears both iOS and Android minimum guidance; commit validation still
comes exclusively from `PlacementEngine`.

### External weather depth is cataloged, bounded, and provider-neutral

The broad six weather kinds remain the cooldown and primary visual identity.
`atmospheric_traits.json` may add zero to two secondary traces using only
visibility, precipitation rate, cloud cover, wind speed, and apparent
temperature already normalized by both current providers. No AQ, pollen,
calendar, new permission, or server input is added in this slice.

Weather materials persist zero to two classified traits and their classifier
version. Crafting presents only the intersection of those traits and the
recipe's affinity list; the user may retain the base form or choose one focus.
That focus, not the full material list, becomes immutable collectible state.
Existing visitor requirements remain unchanged, so a rare trait never becomes
the only route to an unlock.

SQLite schema v2 adds `trait_keys_json` and `trait_schema_version` to weather
materials, plus nullable `focus_trait` and stable `variant_key` on crafted
objects. Existing `object-v1` and `object-v2` collectibles keep their previous
look. New `object-v3` crafts opt into the shared alpha-clipped base-weather and
focus-trait surface/footprint compositor. The compositor reuses the existing 12
assets, so the bounded new image inventory for this slice is zero.
