# Reality Diorama (Flutter)

A local-first iOS and Android prototype based on the **Reality Collection Diorama v6** product specification.

> Collect a brief snapshot of the current weather and optional surroundings, use recent steps as crafting work, build miniature neighborhood objects, and arrange them in a soft pixel-art diorama to discover visitors and new recipes.

## Implemented core loop

- Flutter app shell with Home, Capture, Inventory, Crafting, Placement, Settings, and Codex flows.
- Local SQLite persistence for captures, materials, step buckets, crafted objects, placements, visitor sightings, and unlock metadata.
- Weather cooldown, six broad weather-material classes, partial capture, and fail-closed production errors.
- Native step bridge:
  - iOS: `CMPedometer` daily data for the recent seven days.
  - Android: `TYPE_STEP_COUNTER` with a local daily baseline and reboot-safe carried deltas from installation onward.
  - Explicit fallback: 2,000 work units per day only after the user chooses it or real step access is unavailable.
- Optional foreground BLE scan through a native method channel. The native layer returns aggregate session features only; no peripheral identifier, name, MAC address, or raw advertisement is persisted.
- Recipe-driven crafting with FIFO step spending, construction progress, and transactional material/step/object/placement persistence.
- Deterministic 5×5 isometric diorama renderer implemented with Flame and Flutter canvas primitives.
- Environment grid, connection graph, deterministic visitor rules, transactional visitor rewards, and codex hints.
- Platform weather split:
  - iOS 18+: native WeatherKit through a method channel and WeatherKit attribution.
  - Android: replaceable HTTP weather adapter; the prototype uses Open-Meteo with attribution.
  - Demo weather is available only when `DEMO_MODE=true`.
- Unit tests for cooldowns, step accounting and source changes, classifiers, capture failure boundaries, crafting, placement, and visitor predicates.

## Product boundaries

- No account, developer-operated server, ads, subscription, social graph, or location-history service.
- No background BLE crowd scanning. Surroundings are an explicit foreground scan.
- Nearby BLE signals are **not** represented as people or crowd counts.
- Weather data is regional model data, not a claim of direct measurement at the exact point where the user stands.
- Production weather failures create no fake material.
- Cooldowns, steps, weather materials, scan retries, visitor odds, and collection attempts are not monetized.

## Toolchain

The repository pins Flutter 3.44.9 in `.fvmrc` and requires Dart 3.12 or newer.

```bash
./tool/bootstrap_platforms.sh
flutter pub get
flutter run
```

For an offline deterministic product preview:

```bash
flutter run --dart-define=DEMO_MODE=true
```

## Platform preparation

The repository tracks the product-owned manifests and native bridges, while generated Flutter wrapper files are recreated by `tool/bootstrap_platforms.sh`. The command regenerates Android and iOS wrappers with Flutter 3.44.9, reapplies the tracked bridges, and patches permissions, minimum OS versions, and the WeatherKit entitlement. Run it once after cloning a source archive; CI runs it on every job.

```bash
./tool/bootstrap_platforms.sh
```

For iOS device or distribution builds, enable WeatherKit for the App ID and signing profile in the Apple Developer account. The checked-in entitlement alone does not provision the capability.

See `docs/platform-setup.md` for permissions, signing, provider attribution, and platform differences.

## Validation

```bash
./tool/validate.sh
```

With Flutter installed, validation resolves packages, parses Dart sources with the formatter, runs the analyzer, and executes tests. GitHub Actions additionally regenerates the platform wrappers, builds an Android debug APK, and compiles an iOS simulator build.

## Repository structure

```text
lib/src/domain       immutable game models and pure engines
lib/src/data         SQLite schema and transactional repository
lib/src/platform     method-channel and OS adapters
lib/src/services     capture orchestration and weather/location services
lib/src/diorama      Flame-backed deterministic isometric renderer
lib/src/ui           product screens and widgets
assets/content       versioned recipes, visitors, and balance
android / ios        platform bridges, manifests, and entitlements
docs                 product specification and implementation notes
tool                 bootstrap, validation, archive, and publishing helpers
```

## Publish to GitHub

After cloning the supplied git bundle or source archive, authenticate GitHub CLI and run:

```bash
./tool/publish_github.sh private
```

Replace `private` with `public` when appropriate. The default target is `eiranotes/reality-diorama-flutter`; environment variables can override the owner and repository name. See `docs/repository-publishing.md`.

## Weather providers

- iOS uses Apple Weather through WeatherKit. Settings display the provider mark/notice and legal link returned by WeatherKit.
- Android currently uses `OpenMeteoWeatherGateway` for prototype and evaluation builds. A commercial release must use a provider/plan that permits the intended traffic or replace the adapter.
- The game domain depends only on `WeatherGateway`; provider-specific data does not leak into crafting or visitor rules.

## Art status

The app renders a coherent placeholder diorama from code. Images under `docs/references` are mood and composition references only, not production assets. Production art must use a fixed 2:1 isometric grid, one pixel scale, one light direction, shared atlases, and integer scaling.

## License

No open-source license is granted. All rights reserved by the repository owner.
