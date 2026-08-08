# Platform setup

## Android

Minimum SDK: 26. Target/compile SDK: 35 or newer.

Declared permissions:

- approximate/fine location while in use;
- activity recognition;
- Bluetooth scan/connect on Android 12+;
- legacy Bluetooth/location compatibility declarations on older Android versions;
- network access for the weather provider.

The app does not request background location or run a foreground service. BLE scanning is explicit, foreground-only, and stops after eight seconds.

The step bridge uses `TYPE_STEP_COUNTER`, a local daily baseline, and carried deltas across device reboots. Android does not expose a universal seven-day historical pedometer equivalent through that sensor, so only values observed after installation are recoverable. A newly observed local day starts at zero; the 2,000-unit fallback is used only when the user explicitly selects it or activity data is unavailable.

The prototype Android weather adapter uses Open-Meteo. Settings show attribution and a legal/source link. Replace the adapter or provider plan before commercial traffic if the prototype service terms are insufficient.

## iOS

Minimum deployment target: iOS 18.

Required usage descriptions:

- location while in use;
- Motion & Fitness;
- Bluetooth.

`CMPedometer` supplies recent daily steps. `CoreBluetooth` performs an explicit foreground scan and returns aggregate features. No peripheral identifiers leave the native session.

Current weather comes from native WeatherKit through `com.eiranotes.reality_diorama/weather`. The repository includes `Runner.entitlements` with `com.apple.developer.weatherkit`, but device/distribution builds also require WeatherKit to be enabled for the App ID and signing profile in the Apple Developer account.

Settings request WeatherKit attribution and expose the returned provider mark, notice, and legal page. Production weather errors are fail-closed; demo weather is available only through `--dart-define=DEMO_MODE=true`.

## Permission timing

Permissions are requested in context rather than during onboarding:

1. Location: when the user opens capture for the first time.
2. Motion & Fitness / Activity Recognition: before the first craft or from Settings.
3. Bluetooth: only when the user chooses to collect surroundings.

The selected step source is stored. Changing between actual steps and the daily fallback preserves already spent work but discards unused allowance from the previous source, preventing double credit.

## Wrapper generation and CI

`./tool/bootstrap_platforms.sh` regenerates complete Android and iOS wrappers with the pinned Flutter version and then reapplies:

- Android/iOS sensor bridge source;
- Android API 26 minimum and permission manifest;
- iOS 18 minimum and usage descriptions;
- WeatherKit entitlement and Xcode project attachment.

The command is intended for CI and wrapper recovery. Review its diff before committing in a developer checkout.

GitHub Actions runs the bootstrap before package resolution and validation, then builds an Android debug APK on Ubuntu and an iOS simulator build on macOS.
