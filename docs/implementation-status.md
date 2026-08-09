# Implementation status

## Included in the current repository

- product architecture and versioned content definitions;
- SQLite persistence and transactional crafting/visitor resolution;
- cooldown and resource economy;
- explicit actual-step/fallback-step selection and native bridge contracts;
- iOS WeatherKit adapter and Android prototype HTTP weather adapter;
- production weather/location capture that fails closed;
- Android and iOS foreground BLE aggregation bridges;
- crafting/construction flow;
- 5×5 placement and visitor rules;
- pixel-style isometric prototype renderer shared by the home scene, crafting,
  inventory, and codex with persisted `visualSeed` details;
- inventory, settings, and codex;
- tests, repository contracts, Android/iOS compile CI, and reproducible publish/archive helpers.

## Deliberately not represented as complete

- production pixel atlases and frame animation;
- Apple Developer portal App ID/profile activation for WeatherKit;
- Play Billing/App Store product identifiers;
- home-screen widgets and Android Quick Settings tile;
- production analytics and TestFlight/Play testing gates;
- backup/import UI;
- high-resolution share renderer implementation;
- accessibility, battery, and thermal audit on physical devices.

These are post-core-loop tasks in the v6 roadmap, not silent omissions.

## Capture and persistence hardening

- Production weather failures create no demo/fake material.
- Missing location does not call a provider and does not persist a fake Seoul cell.
- Surroundings-only capture remains available when weather is unavailable.
- Crafting, material consumption, step spending, and initial placement are committed in one SQLite transaction.
- Visitor sightings and their recipe/reward unlock metadata are committed in one SQLite transaction.
- Removing an incomplete placed construction keeps its `building` lifecycle in both memory and SQLite.
- Android BLE scanning is stopped on completion, scan failure, permission race, and activity destruction.
- Current-weather visitor requirements use only a confirmed current weather observation, not a stale stored material.
- Changing step sources preserves spent work but removes unused credit from the previous source.
- App resume and pull-to-refresh synchronize configured steps and advance construction.

## Platform weather status

- iOS: native WeatherKit current weather and attribution method channel; entitlement checked in.
- Android: Open-Meteo prototype gateway with visible attribution; replaceable behind `WeatherGateway`.
- Demo: deterministic weather/location/steps/BLE only when `DEMO_MODE=true`.

Demo gateways do not request real Bluetooth or Motion permissions. The iOS demo
path stores its state in a database separate from production. The audited
simulator loop collected deterministic rain/surroundings, crafted and moved an
alley lamp, and restored the object, placement, and remaining steps after a
process restart.

## Import and validation status

The staged archive import has been replaced by the tracked Flutter source tree. `IMPORT_COMPLETE.md` defines the main-branch completion contract, and `IMPORT_STATUS.md` records `Conclusion: success` together with the validated gates and their release boundary.

GitHub Actions pins Flutter 3.44.9, regenerates the platform wrappers, resolves packages, runs repository and import-contract checks, verifies formatting, runs `flutter analyze` and the full test suite, builds an Android debug APK, and compiles an iOS simulator build. The first complete remote proof passed in `Flutter CI` run #16 on pull request #6; the latest successful `main` run remains authoritative after merge.

The normal Flutter workflow is read-only. A separate `workflow_run` reporter may write only to GitHub Issues: a non-successful `main` run creates or updates `Flutter import requires follow-up`, and a later successful `main` run closes it automatically.

Distribution signing, store configuration, WeatherKit provisioning, production Android weather-provider selection, and physical-device accessibility/battery/thermal testing remain release gates rather than import gates.

The current image-asset scope is one owner-review AppIcon candidate under
`assets/branding/candidates`. Production sprite atlases remain deferred until
the G2 renderer and placement geometry are stable.
