# Decisions

## 2026-08-11

### Request-first is a feature-flagged vertical slice until device evidence exists

PR #12 is integrated locally as the concrete implementation of the Pro-reviewed
request-first pivot, but `REQUEST_FIRST_MODE=true` remains required. This keeps
the current v6 loop available while native audio feature distributions,
interruptions, permission recovery, file-residue behavior, battery, thermal,
accessibility, and 14-day behavior are still unverified. A Draft PR and a
successful simulator/demo build are not evidence for those physical-device
gates.

History requests bind one persisted specimen ID when issued. Archive UI paging
must never redefine that game rule, so capture resolves any missing active
history references through a bounded ID query instead of loading the entire
specimen library or accepting `기준 표본 없음`. The permanent record remains
paginated; only the at-most-two active references are fetched on demand.

Relationship keepsakes retain the same 5×5 `PlacementEngine`, authored rotation
catalog, and eight-object limit as v6. Manual placement, directional movement,
rotation, and return-to-storage are expression tools only: they do not satisfy
requests or mutate relationship progress. Repository writes recheck that the
scene object exists and update exactly one lifecycle row in the same transaction.

All ordinary CI workflows remain source-read-only. Formatting is a validation
failure, not a bot-authored branch mutation. The request-first static gate also
executes the actual embedded table declarations in SQLite so a syntactically
invalid schema cannot pass through string-presence assertions alone.

### Placement mode is a planning surface with one ground-anchor contract

Generated terrain stamps, non-rain global atmosphere emblems, and 104 px
weather footprint halos no longer participate in runtime scene composition.
They remain in their authoring packages with original prompts, sources,
manifests, and hashes; removal from the visible product does not rewrite asset
provenance. Rain keeps its restrained code-rendered motion, and alpha-clipped
object surface patterns remain the bounded weather treatment outside placement
mode.

The editor suppresses scene weather and visitors, lowers fixed-scenery opacity,
and uses code-rendered cell fills, outlines, and anchor squares instead of
decorative target images on the board. The selected footprint remains below
object art, while its small ground-point marker participates at the object's
natural depth. Selection therefore cannot falsify the neighborhood's isometric
occlusion order.

`DioramaGeometry.orderedPlacements()` is shared by painting and hit testing.
`DeterministicObjectRenderer.spriteBoundsAt()` is the visible-object fallback
for selection, and `previewAnchorIn()` aligns long-press drag feedback by the
same normalized sprite ground point used on the board. Direct drags still
preserve the original pointer-to-anchor offset and commit only one validated
cell on release. All 112 directional PNGs must touch the 256 px bottom edge and
keep their alpha bounds centered on that point; the board then maps it to the
front vertex of the complete rotated footprint.

### Persisted outcome copy must describe the stored state

A completed craft reports placement only when its returned lifecycle is
`placed`; a complete object with no valid anchor reports that it was saved to
inventory. Visitor encounters use the currently verified weather kind or an
explicit `unavailable` value. The rendered scene may still use a harmless
fallback palette, but persisted provenance must not turn that fallback into a
claimed observation.

## 2026-08-10

### Capture history is an ambient-effect ledger, not a placement catalog

Each capture card resolves its stored `surroundingMaterialId` and presents that
actual dense, dynamic, stable, or sparse material as a framed effect sample.
Surroundings take precedence when both channels were collected; a weather-only
capture may show its linked weather material, while an unlinked legacy record
uses a neutral trace without inventing a surroundings classification. Placement
scenery and crafted-object art never appear in capture history. The record row
keeps its place, time, and compact source label, and semantics describe the same
sample. This presentation adds no renderer contract, token, or bitmap file.

The diorama no longer composites generated full-screen time or weather PNGs.
They produced vague translucent blocks and made a still image read as falling
weather. Rain alone uses a deterministic eight-frame, 8 fps pixel animation;
its short drops move as one environmental layer over the existing wet-tile
state. When the platform requests reduced motion, the falling layer is omitted
and the persistent environment state carries the weather instead.

Visible product copy follows a state-first rule: show the current state, the
next action, or a required boundary once, rather than narrating the interface.
Regional weather-model limits, sensor non-identification, provider/legal
attribution, recoverable errors, and screen-reader semantics are not removed by
this rule. They may be shortened only when the remaining text keeps the same
meaning.

### Recipe progression is layered and only actionable visitors become goals

The 28-recipe library now unfolds as 10 initial recipes followed by three
deterministic layers containing 7, 7, and 4 recipes. Later visitors may require
an object from an earlier layer, but still expose no more than three visible
conditions. `VisitorProgressionPolicy` treats only explicit object-kind and tag
requirements as recipe gates; weather, time, connections, and environment
values remain live scene conditions rather than catalog locks.

Home targeting and arrival resolution filter through that same actionable set,
so a visitor cannot become the current goal before the player owns a recipe
capable of meeting its explicit prerequisite. The codex remains a complete
field guide and names the first missing prerequisite recipe for later visitors.
An iterative content test computes tiers from a frozen layer snapshot, avoiding
catalog-order shortcuts and proving the exact 10/7/7/4 distribution.

### Permanent capture history uses explicit bounded pages

Capture records remain permanent local history, but the controller loads 24 at
a time using stable `captured_at DESC, id DESC` ordering and a separate exact
count. The inventory does not auto-fetch while the user scrolls: a labeled
48 dp cut-corner button shows loaded versus total records and requests the next
page. This is predictable, accessible, and consistent with the existing pixel
control vocabulary. Narrow widths and large text switch the record grid to one
roomier column. No schema, token, asset, dependency, or retention policy is
added; the former latest-100 visibility ceiling is removed rather than moving
data elsewhere.

### World refresh and visitor selection share one return-loop contract

Cold launch and app resume now refresh steps and construction, passively
prepare capture readiness, then evaluate visitors in that order. Capture,
manual step refresh, step-source configuration, crafting, placement, and
storage changes all evaluate visitors after their state mutation. Passive
refresh checks existing location authorization but never opens a permission
prompt; the focused capture sheet remains the only path that may request it.
Provider failure continues to leave weather visitor requirements unavailable
rather than satisfying them from rendered fallback atmosphere.

`VisitorSelectionPolicy` is the deterministic source for both the home target
and the actual arrival candidate. Satisfied unseen visitors always outrank
repeat visitors. After all visitors are discovered, the oldest repeat-ready
satisfied visitor wins, preventing catalog order from monopolizing six-hour
returns. Home exposes the remaining repeat wait and the exact placement
condition that a valid drag would complete.

### Patterns are evidence, not currency, and repeat visits are scene memories

Time and representative-weather patterns can explain matching time/weather
visitor requirements in capture results, inventory, home, and codex. This link
never consumes a pattern, never auto-satisfies a visitor, and never gates a
recipe. Signal-strength bands and surroundings patterns remain collectible
context rather than being forced into visitor requirements that do not exist.

SQLite schema v4 adds append-only `visitor_encounters` beside the existing
per-visitor latest-sighting row. Each encounter stores only visit time, coarse
weather/time variant, placed object IDs, and the already-bounded scene snapshot;
raw Bluetooth data is still prohibited. Migration backfills one legacy
encounter per existing sighting. The controller loads grouped counts rather
than scanning the history, while repository callers may request at most five
recent encounters for a visitor.

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

Board selection fills and connection emphasis remain code-rendered. They are
interaction feedback rather than collectible art and must scale cleanly with
layout and accessibility.

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

### Placement art is anchored to the rotated footprint's front vertex

Placement rows continue to persist the top-left logical anchor cell. Rendering
must not attach a sprite's bottom pixel directly to that cell center: doing so
raises 1x1 art by half a tile and misplaces 1x2 art by an additional occupied
cell after rotation. `DioramaGeometry.placementGroundAnchor` derives the
front-most occupied cell and adds half the tile height, so the normalized PNG's
bottom-center point lands on the footprint's front vertex.

The inverse projection is used for catalog drops, and hit testing uses the same
derived point. Paint order follows the derived front depth rather than the
stored anchor depth. Selection remains a tile fill below the art plus a small
ground-point marker painted at the selected object's natural depth; it never
lifts the object above a physically nearer neighbor or draws a diamond across
the object's body.

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
