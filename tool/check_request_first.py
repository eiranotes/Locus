#!/usr/bin/env python3
"""Static contracts for the additive request-first v7 foundation."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load(relative: str) -> dict:
    path = ROOT / relative
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        fail(f"{relative}: invalid JSON: {exc}")


def require_file(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        fail(f"missing request-first file: {relative}")
    return path.read_text(encoding="utf-8")


def check_content() -> None:
    visitors = {
        item["id"] for item in load("assets/content/visitors.json")["visitors"]
    }
    recipes = {
        item["id"] for item in load("assets/content/recipes.json")["recipes"]
    }
    axes_doc = load("assets/content/sense_axes.json")
    requests_doc = load("assets/content/request_templates.json")
    relationships_doc = load("assets/content/relationship_tracks.json")
    scene_doc = load("assets/content/scene_objects.json")
    balance = load("assets/content/request_first_balance.json")

    axes = axes_doc.get("axes", [])
    axis_ids = [item.get("id") for item in axes]
    if len(axis_ids) != len(set(axis_ids)):
        fail("request-first sense axes must be unique")
    expected_axes = {
        "loudness",
        "intermittency",
        "rhythmicity",
        "dynamicRange",
        "spectralBrightness",
        "timeBand",
    }
    if set(axis_ids) != expected_axes:
        fail("request-first sense axis inventory changed without a schema update")
    initial_axes = {
        item["id"] for item in axes if item.get("initiallyUnlocked") is True
    }
    if initial_axes != {"loudness", "intermittency", "timeBand"}:
        fail("initial request-first axes must remain loudness/intermittency/timeBand")

    templates = requests_doc.get("templates", [])
    template_ids = [item.get("id") for item in templates]
    if len(templates) < 12 or len(template_ids) != len(set(template_ids)):
        fail("request-first needs at least 12 unique authored templates")
    known_tiers = {"everyday", "outing"}
    known_history = {None, "none", "similar", "contrast"}
    for template in templates:
        if not template.get("visitorIds"):
            fail(f"template {template.get('id')} needs visitors")
        if not set(template["visitorIds"]).issubset(visitors):
            fail(f"template {template['id']} references an unknown visitor")
        constraints = template.get("constraints", [])
        if not constraints:
            fail(f"template {template['id']} needs constraints")
        constraint_axes = {item.get("axis") for item in constraints}
        if not constraint_axes.issubset(expected_axes):
            fail(f"template {template['id']} references an unknown axis")
        if (
            template.get("minimumRelationshipStage", 0) == 0
            and not constraint_axes.issubset(initial_axes)
        ):
            fail(f"stage-zero template {template['id']} uses a locked axis")
        if template.get("accessTier") not in known_tiers:
            fail(f"template {template['id']} has an invalid access tier")
        if template.get("historyComparison") not in known_history:
            fail(f"template {template['id']} has an invalid history comparison")
        for constraint in constraints:
            tolerance = constraint.get("tolerance", 0.20)
            weight = constraint.get("weight", 1.0)
            if not 0 < tolerance <= 1:
                fail(f"template {template['id']} has invalid tolerance")
            if not 0 < weight <= 4:
                fail(f"template {template['id']} has invalid weight")
            minimum = constraint.get("minimum")
            maximum = constraint.get("maximum")
            if minimum is not None and not 0 <= minimum <= 1:
                fail(f"template {template['id']} minimum is outside 0..1")
            if maximum is not None and not 0 <= maximum <= 1:
                fail(f"template {template['id']} maximum is outside 0..1")
            if minimum is not None and maximum is not None and minimum > maximum:
                fail(f"template {template['id']} has an inverted range")

    objects = scene_doc.get("objects", [])
    object_ids = [item.get("id") for item in objects]
    if len(objects) < 4 or len(object_ids) != len(set(object_ids)):
        fail("request-first scene objects must be unique and non-trivial")
    for item in objects:
        if item.get("legacyRecipeId") not in recipes:
            fail(f"scene object {item.get('id')} has no reusable recipe art")

    tracks = relationships_doc.get("tracks", [])
    track_visitors = [item.get("visitorId") for item in tracks]
    if len(tracks) < 3 or len(track_visitors) != len(set(track_visitors)):
        fail("request-first needs at least three unique relationship tracks")
    for track in tracks:
        if track.get("visitorId") not in visitors:
            fail(f"relationship track {track.get('visitorId')} is unknown")
        counts = [item.get("fulfilledCount") for item in track.get("milestones", [])]
        if counts != [1, 3, 6, 10]:
            fail(f"relationship track {track['visitorId']} must use 1/3/6/10")
        for milestone in track["milestones"]:
            axis = milestone.get("unlockAxis")
            if axis is not None and axis not in expected_axes:
                fail(f"relationship track {track['visitorId']} unlocks an unknown axis")
            scene = milestone.get("sceneObjectId")
            if scene is not None and scene not in object_ids:
                fail(
                    f"relationship track {track['visitorId']} grants a missing scene object"
                )

    if balance.get("gameDayBoundaryHour") != 4:
        fail("request-first local day must start at 04:00")
    if balance.get("requestSlots") != 2:
        fail("request-first MVP must keep exactly two request slots")
    if balance.get("specimenCaptureSeconds") != 4:
        fail("request-first MVP capture duration must remain four seconds")
    if balance.get("gridColumns") != 5 or balance.get("gridRows") != 5:
        fail("request-first must preserve the 5x5 diorama")
    if balance.get("activeObjectLimit") != 8:
        fail("request-first must preserve the eight-object scene limit")


def check_source_contracts() -> None:
    required = [
        "lib/src/domain/entities_specimens.dart",
        "lib/src/domain/entities_requests.dart",
        "lib/src/domain/entities_relationships.dart",
        "lib/src/domain/entities_scene.dart",
        "lib/src/domain/request_first_catalog.dart",
        "lib/src/domain/local_game_day.dart",
        "lib/src/domain/engines/request_scheduler.dart",
        "lib/src/domain/engines/specimen_matcher.dart",
        "lib/src/domain/engines/relationship_engine.dart",
        "lib/src/platform/sense_sampler.dart",
        "lib/src/services/specimen_capture_coordinator.dart",
        "lib/src/data/request_first_repository.dart",
    ]
    for relative in required:
        require_file(relative)

    entities = require_file("lib/src/domain/entities.dart")
    for part in (
        "entities_specimens.dart",
        "entities_requests.dart",
        "entities_relationships.dart",
        "entities_scene.dart",
    ):
        if f"part '{part}';" not in entities:
            fail(f"entities.dart is missing {part}")

    database = require_file("lib/src/data/database.dart")
    if "static const int schemaVersion = 5" not in database:
        fail("request-first foundation requires database schema v5")
    for table in (
        "specimens",
        "visitor_requests",
        "specimen_matches",
        "specimen_assignments",
        "visitor_relationships",
        "relationship_events",
        "scene_objects",
        "scene_placements",
        "sense_profile",
    ):
        if f"CREATE TABLE IF NOT EXISTS {table}" not in database:
            fail(f"database schema is missing {table}")
    for fragment in (
        "specimen_id TEXT NOT NULL UNIQUE",
        "request_id TEXT NOT NULL UNIQUE",
    ):
        if fragment not in database:
            fail(f"database is missing assignment exclusivity: {fragment}")

    repository = require_file("lib/src/data/request_first_repository.dart")
    for fragment in (
        "Future<void> saveSpecimenCapture",
        "Future<void> assignSpecimen",
        "Stored specimen match does not satisfy the request",
        "Specimen or request has already been assigned",
        "await _db.transaction",
    ):
        if fragment not in repository:
            fail(f"request-first repository is missing {fragment}")

    scheduler = require_file("lib/src/domain/engines/request_scheduler.dart")
    for fragment in (
        "required List<String> historySpecimenIds",
        "historySpecimenId: historySpecimenId",
    ):
        if fragment not in scheduler:
            fail(f"request scheduler is missing history binding: {fragment}")

    sampler = require_file("lib/src/platform/sense_sampler.dart")
    if "abstract interface class SenseSampler" not in sampler:
        fail("SenseSampler boundary is missing")
    if "DemoSenseSampler" not in sampler or "UnavailableSenseSampler" not in sampler:
        fail("request-first sampler needs explicit demo and unavailable states")


def main() -> None:
    check_content()
    check_source_contracts()
    print("request-first foundation checks passed")


if __name__ == "__main__":
    main()
