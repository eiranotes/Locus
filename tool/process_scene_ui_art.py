#!/usr/bin/env python3
"""Build and validate the 50-piece Locus scene and UI pixel-art pack."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "artifacts/imagegen/locus-scene-ui-v1"
SOURCES = PACKAGE / "sources"
OUTPUT = ROOT / "assets/art/generated/v1"
MANIFEST = PACKAGE / "manifest.json"
CONTACT_SHEET = PACKAGE / "contact-sheet.png"
CHROMA_SCRIPT = (
    Path.home()
    / ".codex-shared/state/skills/.system/imagegen/scripts/remove_chroma_key.py"
)


@dataclass(frozen=True)
class Sheet:
    source: str
    category: str
    names: tuple[str, ...]
    canvas: int
    content: int


SHEETS = (
    Sheet(
        "terrain-a.png",
        "terrain",
        (
            "pebbles",
            "moss",
            "grass_blades",
            "clover",
            "mushrooms",
            "autumn_leaves",
            "wildflowers",
            "twig",
            "fern",
            "drain_grate",
        ),
        64,
        54,
    ),
    Sheet(
        "terrain-b.png",
        "terrain",
        (
            "cracked_cobble",
            "chalk_star",
            "puddle_glint",
            "wet_leaf",
            "snow_tuft",
            "dry_weed",
            "acorns",
            "flower_petals",
            "stepping_marks",
            "crack_grass",
        ),
        64,
        54,
    ),
    Sheet(
        "atmosphere.png",
        "atmosphere",
        (
            "rain_ripples",
            "mist_wisp",
            "frost_sparkles",
            "warm_motes",
            "wind_leaves",
            "dawn_sparkle",
            "morning_rays",
            "evening_windows",
            "night_moths",
            "falling_raindrops",
        ),
        96,
        82,
    ),
    Sheet(
        "editor.png",
        "editor",
        (
            "valid_target",
            "selected_target",
            "invalid_target",
            "grab_hand",
            "place_chevron",
            "arrow_left",
            "arrow_up",
            "arrow_down",
            "arrow_right",
            "rotate",
        ),
        64,
        54,
    ),
    Sheet(
        "actions.png",
        "action",
        (
            "capture",
            "craft",
            "place",
            "rotate",
            "store",
            "weather",
            "surroundings",
            "visitor",
            "codex",
            "settings",
        ),
        96,
        82,
    ),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def png_contract(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as handle:
        if handle.read(8) != b"\x89PNG\r\n\x1a\n":
            raise ValueError(f"{path}: not a PNG")
        length = struct.unpack(">I", handle.read(4))[0]
        if handle.read(4) != b"IHDR" or length != 13:
            raise ValueError(f"{path}: invalid IHDR")
        width, height, _, color_type, _, _, _ = struct.unpack(
            ">IIBBBBB", handle.read(13)
        )
    return width, height, color_type


def run(*arguments: str) -> None:
    subprocess.run(arguments, check=True)


def cell_bounds(length: int, count: int, index: int) -> tuple[int, int]:
    return round(length * index / count), round(length * (index + 1) / count)


def process() -> None:
    if shutil.which("magick") is None:
        raise SystemExit("ImageMagick is required to process scene/UI art")
    if not CHROMA_SCRIPT.is_file():
        raise SystemExit(f"Missing chroma-key helper: {CHROMA_SCRIPT}")

    assets: list[dict[str, object]] = []
    source_records: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="locus-scene-ui-") as raw_tmp:
        temporary = Path(raw_tmp)
        for sheet in SHEETS:
            source = SOURCES / sheet.source
            width, height, _ = png_contract(source)
            source_records.append(
                {
                    "path": source.relative_to(ROOT).as_posix(),
                    "width": width,
                    "height": height,
                    "sha256": sha256(source),
                }
            )
            keyed = temporary / sheet.source
            run(
                "python3",
                str(CHROMA_SCRIPT),
                "--input",
                str(source),
                "--out",
                str(keyed),
                "--key-color",
                "#FF00FF",
                "--tolerance",
                "72",
                "--spill-cleanup",
                "--force",
            )
            category_output = OUTPUT / sheet.category
            category_output.mkdir(parents=True, exist_ok=True)
            for index, name in enumerate(sheet.names):
                left, right = cell_bounds(width, 5, index % 5)
                top, bottom = cell_bounds(height, 2, index // 5)
                output = category_output / f"{name}.png"
                run(
                    "magick",
                    str(keyed),
                    "-crop",
                    f"{right - left}x{bottom - top}+{left}+{top}",
                    "+repage",
                    "-trim",
                    "+repage",
                    "-filter",
                    "point",
                    "-resize",
                    f"{sheet.content}x{sheet.content}>",
                    "-gravity",
                    "center",
                    "-background",
                    "none",
                    "-extent",
                    f"{sheet.canvas}x{sheet.canvas}",
                    "-define",
                    "png:color-type=6",
                    str(output),
                )
                output_width, output_height, color_type = png_contract(output)
                assets.append(
                    {
                        "name": name,
                        "category": sheet.category,
                        "path": output.relative_to(ROOT).as_posix(),
                        "source": source.relative_to(ROOT).as_posix(),
                        "sourceCell": index,
                        "width": output_width,
                        "height": output_height,
                        "pngColorType": color_type,
                        "sha256": sha256(output),
                    }
                )

    payload = {
        "schemaVersion": 1,
        "package": "locus-scene-ui-v1",
        "generator": "OpenAI built-in image_gen",
        "styleReferences": [
            "artifacts/imagegen/locus-art-v1/contact-sheet.png",
            "artifacts/imagegen/locus-collection-expansion-v1/contact-sheet.png",
        ],
        "chromaKey": "#FF00FF",
        "sources": sorted(source_records, key=lambda item: str(item["path"])),
        "assets": sorted(assets, key=lambda item: str(item["path"])),
    }
    MANIFEST.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    build_contact_sheet(assets)
    validate()


def build_contact_sheet(assets: list[dict[str, object]]) -> None:
    with tempfile.TemporaryDirectory(prefix="locus-scene-ui-contact-") as raw_tmp:
        temporary = Path(raw_tmp)
        thumbnails: list[Path] = []
        for index, item in enumerate(assets):
            thumbnail = temporary / f"{index:02d}.png"
            run(
                "magick",
                str(ROOT / str(item["path"])),
                "-filter",
                "point",
                "-resize",
                "72x72",
                "-gravity",
                "center",
                "-background",
                "#06131D",
                "-extent",
                "88x88",
                str(thumbnail),
            )
            thumbnails.append(thumbnail)
        rows: list[Path] = []
        for row in range(5):
            output = temporary / f"row-{row}.png"
            run(
                "magick",
                *(str(path) for path in thumbnails[row * 10 : row * 10 + 10]),
                "+append",
                str(output),
            )
            rows.append(output)
        run("magick", *(str(path) for path in rows), "-append", str(CONTACT_SHEET))


def validate() -> None:
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = payload.get("assets", [])
    expected = {
        (sheet.category, name)
        for sheet in SHEETS
        for name in sheet.names
    }
    actual = {(str(item["category"]), str(item["name"])) for item in assets}
    if actual != expected or len(assets) != 50:
        raise SystemExit(
            f"Scene/UI inventory mismatch: expected=50 actual={len(assets)}"
        )
    hashes: set[str] = set()
    for item in (*payload.get("sources", []), *assets):
        path = ROOT / str(item["path"])
        if not path.is_file():
            raise SystemExit(f"Missing scene/UI art file: {path}")
        width, height, color_type = png_contract(path)
        if width != item["width"] or height != item["height"]:
            raise SystemExit(f"Dimension mismatch: {path}")
        if "pngColorType" in item and color_type != 6:
            raise SystemExit(f"Runtime asset must be RGBA: {path}")
        if sha256(path) != item["sha256"]:
            raise SystemExit(f"Hash mismatch: {path}")
        if "pngColorType" in item:
            hashes.add(str(item["sha256"]))
    if len(hashes) != 50:
        raise SystemExit("Every scene/UI runtime asset must have a distinct payload")
    if not CONTACT_SHEET.is_file():
        raise SystemExit(f"Missing contact sheet: {CONTACT_SHEET}")
    print("scene/UI art validation passed (50 distinct RGBA assets)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    if args.validate_only:
        validate()
    else:
        process()


if __name__ == "__main__":
    main()
