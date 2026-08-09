#!/usr/bin/env python3
"""Fast repository checks that do not require the Flutter SDK."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_json(relative: str) -> dict:
    path = ROOT / relative
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        fail(f"{relative}: invalid JSON: {exc}")


def check_content() -> None:
    recipes_doc = load_json("assets/content/recipes.json")
    visitors_doc = load_json("assets/content/visitors.json")
    balance = load_json("assets/content/balance.json")
    recipes = recipes_doc.get("recipes", [])
    visitors = visitors_doc.get("visitors", [])
    recipe_ids = [item["id"] for item in recipes]
    visitor_ids = [item["id"] for item in visitors]
    if len(recipe_ids) != len(set(recipe_ids)):
        fail("duplicate recipe id")
    if len(visitor_ids) != len(set(visitor_ids)):
        fail("duplicate visitor id")
    known_requirements = {
        "wetCells", "lightCells", "warmCells", "coolCells",
        "connectedLights", "stableConnections", "farConnections",
        "sequentialConnections", "highObjects", "quietZones",
        "taggedObjects", "objectTag", "objectKind", "timeBand", "weatherKind",
    }
    reward_recipe_ids: set[str] = set()
    for visitor in visitors:
        for requirement in visitor.get("requirements", []):
            if requirement.get("kind") not in known_requirements:
                fail(f"visitor {visitor['id']} uses unsupported requirement {requirement.get('kind')}")
        reward = visitor["reward"]
        if reward["kind"] == "recipe":
            if reward["value"] not in recipe_ids:
                fail(f"visitor {visitor['id']} rewards missing recipe {reward['value']}")
            reward_recipe_ids.add(reward["value"])
    initial_ids = {item["id"] for item in recipes if item["initiallyUnlocked"]}
    unreachable = set(recipe_ids) - initial_ids - reward_recipe_ids
    if unreachable:
        fail(f"recipes have no initial or visitor unlock path: {sorted(unreachable)}")
    if balance["gridColumns"] != 5 or balance["gridRows"] != 5:
        fail("MVP diorama grid must remain 5x5")
    if balance["activeObjectLimit"] > balance["gridColumns"] * balance["gridRows"]:
        fail("active object limit exceeds grid cells")
    if not 2 <= balance["surroundingScanSeconds"] <= 15:
        fail("surrounding scan duration must be between 2 and 15 seconds")


def strip_dart_comments_and_strings(source: str) -> str:
    output: list[str] = []
    i = 0
    state = "code"
    quote = ""
    triple = False
    while i < len(source):
        char = source[i]
        next_two = source[i : i + 2]
        if state == "code":
            if next_two == "//":
                state = "line_comment"
                output.extend("  ")
                i += 2
                continue
            if next_two == "/*":
                state = "block_comment"
                output.extend("  ")
                i += 2
                continue
            if char in {"'", '"'}:
                quote = char
                triple = source[i : i + 3] == char * 3
                state = "string"
                count = 3 if triple else 1
                output.extend(" " * count)
                i += count
                continue
            output.append(char)
            i += 1
            continue
        if state == "line_comment":
            if char == "\n":
                state = "code"
                output.append("\n")
            else:
                output.append(" ")
            i += 1
            continue
        if state == "block_comment":
            if next_two == "*/":
                state = "code"
                output.extend("  ")
                i += 2
            else:
                output.append("\n" if char == "\n" else " ")
                i += 1
            continue
        if state == "string":
            if char == "\\":
                output.extend("  ")
                i += min(2, len(source) - i)
                continue
            if triple and source[i : i + 3] == quote * 3:
                state = "code"
                output.extend("   ")
                i += 3
                continue
            if not triple and char == quote:
                state = "code"
                output.append(" ")
                i += 1
                continue
            output.append("\n" if char == "\n" else " ")
            i += 1
    if state in {"string", "block_comment"}:
        fail(f"unterminated Dart {state}")
    return "".join(output)


def check_dart_structure() -> None:
    openers = {"(": ")", "[": "]", "{": "}"}
    closers = {value: key for key, value in openers.items()}
    package_prefix = "package:reality_diorama/"
    for path in sorted([*(ROOT / "lib").rglob("*.dart"), *(ROOT / "test").rglob("*.dart")]):
        relative = path.relative_to(ROOT)
        source = path.read_text(encoding="utf-8")
        if not source.endswith("\n"):
            fail(f"{relative}: missing trailing newline")
        stripped = strip_dart_comments_and_strings(source)
        stack: list[tuple[str, int]] = []
        for index, char in enumerate(stripped):
            if char in openers:
                stack.append((char, index))
            elif char in closers:
                if not stack or stack[-1][0] != closers[char]:
                    fail(f"{relative}: mismatched delimiter near character {index}")
                stack.pop()
        if stack:
            fail(f"{relative}: unclosed delimiter {stack[-1][0]}")
        for match in re.finditer(r"import\s+'([^']+)';", source):
            uri = match.group(1)
            if uri.startswith(package_prefix):
                target = ROOT / "lib" / uri[len(package_prefix) :]
                if not target.exists():
                    fail(f"{relative}: unresolved import {uri}")
        for match in re.finditer(r"part\s+['\"]([^'\"]+)['\"]\s*;", source):
            target = path.parent / match.group(1)
            if not target.exists():
                fail(f"{relative}: unresolved part {match.group(1)}")


def _dart_library_owner(path: Path) -> Path:
    source = path.read_text(encoding="utf-8")
    match = re.search(r"^part\s+of\s+['\"]([^'\"]+)['\"]\s*;", source, re.MULTILINE)
    return path if match is None else (path.parent / match.group(1)).resolve()


def _package_imports(source: str) -> set[Path]:
    prefix = "package:reality_diorama/"
    return {
        (ROOT / "lib" / uri[len(prefix) :]).resolve()
        for uri in re.findall(r"import\s+['\"]([^'\"]+)['\"]\s*;", source)
        if uri.startswith(prefix)
    }


def check_internal_type_imports() -> None:
    lib_files = sorted((ROOT / "lib").rglob("*.dart"))
    definitions: dict[str, list[Path]] = {}
    pattern = re.compile(r"^(?:abstract\s+interface\s+|abstract\s+|final\s+|sealed\s+)?(?:class|enum|mixin)\s+(\w+)", re.MULTILINE)
    library_by_file = {path.resolve(): _dart_library_owner(path) for path in lib_files}
    for path in lib_files:
        owner = library_by_file[path.resolve()]
        stripped = strip_dart_comments_and_strings(path.read_text(encoding="utf-8"))
        for name in pattern.findall(stripped):
            if not name.startswith("_"):
                definitions.setdefault(name, []).append(owner)
    for path in [*lib_files, *sorted((ROOT / "test").rglob("*.dart"))]:
        resolved = path.resolve()
        source = path.read_text(encoding="utf-8")
        stripped = strip_dart_comments_and_strings(source)
        library = library_by_file.get(resolved, resolved)
        import_source = source
        if library != resolved and library.exists():
            import_source += "\n" + library.read_text(encoding="utf-8")
        imports = _package_imports(import_source)
        for name, owners in definitions.items():
            if library in owners or not re.search(rf"\b{re.escape(name)}\b", stripped):
                continue
            if not any(owner in imports for owner in owners):
                owners_text = ", ".join(str(owner.relative_to(ROOT)) for owner in owners)
                fail(f"{path.relative_to(ROOT)}: {name} requires direct import of {owners_text}")


def check_native_contracts() -> None:
    step_channel = "com.eiranotes.reality_diorama/steps"
    ambient_channel = "com.eiranotes.reality_diorama/ambient"
    weather_channel = "com.eiranotes.reality_diorama/weather"
    step_dart = ROOT / "lib/src/platform/step_source.dart"
    ambient_dart = ROOT / "lib/src/platform/ambient_scanner.dart"
    weather_dart = ROOT / "lib/src/services/weather_gateway.dart"
    android_native = ROOT / "android/app/src/main/kotlin/com/eiranotes/reality_diorama/MainActivity.kt"
    ios_native = ROOT / "ios/Runner/AppDelegate.swift"
    paths = [step_dart, ambient_dart, weather_dart, android_native, ios_native]
    text = {path: path.read_text(encoding="utf-8") for path in paths}
    if step_channel not in text[step_dart] or ambient_channel not in text[ambient_dart]:
        fail("Dart platform channels are incomplete")
    for path in (android_native, ios_native):
        for channel in (step_channel, ambient_channel):
            if channel not in text[path]:
                fail(f"{path.relative_to(ROOT)}: missing channel {channel}")
    if weather_channel not in text[weather_dart] or weather_channel not in text[ios_native]:
        fail("native WeatherKit channel is incomplete")
    if "import WeatherKit" not in text[ios_native]:
        fail("ios/Runner/AppDelegate.swift: missing WeatherKit import")
    for forbidden in ("device.name", "peripheral.name", "advertisementData["):
        for path in paths:
            if forbidden in text[path]:
                fail(f"{path.relative_to(ROOT)} reads forbidden identity data")


def check_weatherkit_unit_contract() -> None:
    bridge = (ROOT / "ios/Runner/AppDelegate.swift").read_text(encoding="utf-8")
    for fragment in ("precipitationIntensity.converted(to: .metersPerSecond)", "* 3_600_000"):
        if fragment not in bridge:
            fail("WeatherKit precipitation must be normalized to millimeters per hour")


def check_atomic_persistence_contracts() -> None:
    repository = (ROOT / "lib/src/data/game_repository.dart").read_text(encoding="utf-8")
    for fragment in ("Future<void> saveCrafting(", "Placement? placement", "await _db.transaction", "Future<void> saveVisitorResolution", "Future<void> removePlacement(", "required ObjectLifecycle lifecycle", "'unlocked_recipe_ids'", "'unlocked_reward_keys'"):
        if fragment not in repository:
            fail(f"game_repository.dart: missing atomic persistence contract {fragment}")


def check_product_contracts() -> None:
    main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
    if "ResilientWeatherGateway" in main or "fallback: const DemoWeatherGateway" in main:
        fail("production weather must not silently fall back to demo data")
    if "PlatformWeatherGateway()" not in main:
        fail("production builds must select the platform weather gateway")
    controller = (ROOT / "lib/src/app/app_controller.dart").read_text(encoding="utf-8")
    service = (ROOT / "lib/src/services/step_sync_service.dart").read_text(encoding="utf-8")
    crafting = (ROOT / "lib/src/ui/screens/crafting_screen.dart").read_text(encoding="utf-8")
    database = (ROOT / "lib/src/data/database.dart").read_text(encoding="utf-8")
    info_plist = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
    android_manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
    for fragment in ("StepTrackingMode.undecided", "configureStepTracking", "step_tracking_mode"):
        if fragment not in controller:
            fail(f"app_controller.dart: missing step contract {fragment}")
    if "syncReal" not in service or "syncFallback" not in service or "sourceChangeBaseline" not in service or "observedSteps: bucket.spentSteps" not in service:
        fail("step source boundaries are incomplete")
    if "Permission.activityRecognition.request()" not in crafting:
        fail("motion permission must be requested in crafting context")
    if "db.setJournalMode('WAL')" not in database:
        fail("database must enable WAL through the cross-platform sqflite helper")
    if "demoMode ? demoDatabaseName : productionDatabaseName" not in database:
        fail("deterministic demo data must use a database isolated from production")
    for fragment in ("CFBundleExecutable", "$(EXECUTABLE_NAME)", "<string>Locus</string>"):
        if fragment not in info_plist:
            fail(f"ios/Runner/Info.plist: missing launch contract {fragment}")
    if 'android:label="Locus"' not in android_manifest:
        fail("Android application label must match the Locus product identity")
    capture = (ROOT / "lib/src/ui/screens/capture_sheet.dart").read_text(encoding="utf-8")
    if "include && !controller.demoMode" not in capture:
        fail("demo capture must not request a real Bluetooth permission")
    renderer = (ROOT / "lib/src/diorama/object_renderer.dart").read_text(encoding="utf-8")
    seeded_visuals = (ROOT / "lib/src/domain/engines/seeded_visuals.dart").read_text(encoding="utf-8")
    scene = (ROOT / "lib/src/diorama/diorama_game.dart").read_text(encoding="utf-8")
    if "stableSeed" not in renderer or "ObjectVisualDescriptor" not in renderer:
        fail("object renderer must consume the deterministic visual contract")
    if "ObjectVisualDescriptor.fromCraftedObject(" not in scene:
        fail("home diorama must use the shared crafted-object renderer")
    for fragment in (
        "legacyObjectGeneratorVersion = 'object-v1'",
        "currentObjectGeneratorVersion = 'object-v2'",
        "timeBand: weather.timeBand",
    ):
        if fragment not in seeded_visuals:
            fail(f"seeded_visuals.dart: missing versioned visual contract {fragment}")
    for relative in (
        "lib/src/ui/screens/crafting_screen.dart",
        "lib/src/ui/screens/inventory_screen.dart",
        "lib/src/ui/screens/codex_screen.dart",
    ):
        surface = (ROOT / relative).read_text(encoding="utf-8")
        if "ObjectVisualPreview" not in surface:
            fail(f"{relative}: missing shared object preview")
        if "objectIcon(" in surface:
            fail(f"{relative}: must not substitute a Material icon for an object")
    if "com.apple.developer.weatherkit" not in (ROOT / "ios/Runner/Runner.entitlements").read_text(encoding="utf-8"):
        fail("WeatherKit entitlement is missing")


def check_tools_and_ci() -> None:
    workflow = (ROOT / ".github/workflows/flutter.yml").read_text(encoding="utf-8")
    if workflow.count("./tool/bootstrap_platforms.sh") < 2 or "flutter build apk" not in workflow or "flutter build ios --simulator" not in workflow:
        fail("Flutter CI must bootstrap and compile Android and iOS")
    bootstrap = (ROOT / "tool/bootstrap_platforms.sh").read_text(encoding="utf-8")
    for fragment in ("BRIDGE_DIR=", "mktemp -d", "flutter create", "MainActivity.kt", "AppDelegate.swift"):
        if fragment not in bootstrap:
            fail(f"bootstrap_platforms.sh: missing bridge preservation contract {fragment}")
    helper = (ROOT / "tool/publish_github.sh").read_text(encoding="utf-8")
    for fragment in ("prepare_origin", "git remote rename origin source-bundle", "gh repo create", "git push -u origin"):
        if fragment not in helper:
            fail(f"publish_github.sh: missing contract {fragment}")
    if "archive_root = Path('reality-diorama-flutter')" not in (ROOT / "tool/create_source_archive.sh").read_text(encoding="utf-8"):
        fail("source archive root must remain stable")


def check_required_files() -> None:
    required = [
        "README.md", "LICENSE", "AGENTS.md", ".metadata", "pubspec.yaml",
        ".github/workflows/flutter.yml", "docs/product-spec-v6.md",
        "docs/implementation-status.md", "docs/repository-publishing.md",
        "lib/main.dart", "android/app/src/main/AndroidManifest.xml",
        "ios/Runner/Info.plist", "ios/Runner/Runner.entitlements",
        "test/cooldown_engine_test.dart", "test/diorama_rules_test.dart",
        "test/capture_services_test.dart", "test/step_sync_service_test.dart",
        "tool/bootstrap_platforms.sh", "tool/publish_github.sh",
    ]
    missing = [item for item in required if not (ROOT / item).exists()]
    if missing:
        fail(f"missing required files: {missing}")
    if (ROOT / "bootstrap").exists():
        fail("temporary bootstrap import artifacts must not ship")


def main() -> None:
    check_required_files()
    check_content()
    check_dart_structure()
    check_internal_type_imports()
    check_native_contracts()
    check_weatherkit_unit_contract()
    check_atomic_persistence_contracts()
    check_product_contracts()
    check_tools_and_ci()
    print("repository checks passed")


if __name__ == "__main__":
    main()
