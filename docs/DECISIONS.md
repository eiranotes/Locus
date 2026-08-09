# Decisions

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

Board selection fills, valid-anchor markers, connection emphasis, and direction
controls remain code-rendered. They are stateful interaction feedback rather
than collectible art and must scale cleanly with layout and accessibility.

All editor actions query the same `PlacementEngine` validation used by commits.
Invalid moves and rotations are disabled before mutation, selected footprints
and valid anchors are visible on the board, and only connections involving the
selected object remain emphasized. Direct drag is deferred until coordinate,
gesture-cancellation, and accessibility behavior can be tested together.

The editor catalog includes every crafted object, not only rows already present
in the placements table. Stored or temporarily unplaced construction objects
remain selectable, may preview any catalog-supported direction, and are written
back only after the user presses the explicit empty-cell placement action. The
first cell is deterministic row-major order; normal collision, footprint, and
active-object-limit validation remains authoritative.

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
