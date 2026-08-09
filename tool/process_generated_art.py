#!/usr/bin/env python3
"""Build and validate the Locus generated-art package.

Processing requires ImageMagick's `magick` executable. Validation uses only the
Python standard library so repository checks can run without the authoring tool.
"""

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
PACKAGE = ROOT / "artifacts/imagegen/locus-art-v1"
SOURCES = PACKAGE / "sources"
OUTPUT = ROOT / "assets/art/generated/v1"
MANIFEST = PACKAGE / "manifest.json"


@dataclass(frozen=True)
class Pack:
    source: str
    columns: int
    rows: int
    canvas: int
    content: int
    gravity: str
    key_fuzz: str
    names: tuple[str, ...]


PACKS = (
    Pack(
        "objects.png",
        5,
        2,
        256,
        224,
        "south",
        "45%",
        (
            "object_alley_lamp",
            "object_signpost",
            "object_planter",
            "object_bench",
            "object_stairs",
            "object_tree",
            "object_bus_stop",
            "object_pond",
            "object_bridge",
            "object_tower",
        ),
    ),
    Pack(
        "visitors.png",
        3,
        2,
        192,
        168,
        "south",
        "45%",
        (
            "visitor_umbrella_walker",
            "visitor_night_moth",
            "visitor_roof_bird",
            "visitor_fog_cat",
            "visitor_transfer_guest",
            "visitor_light_swarm",
        ),
    ),
    Pack(
        "scenery.png",
        4,
        2,
        256,
        224,
        "south",
        "45%",
        (
            "scenery_house",
            "scenery_workshop",
            "scenery_kiosk",
            "scenery_shed",
            "scenery_tree",
            "scenery_bench",
            "scenery_fence",
            "scenery_path_junction",
        ),
    ),
    Pack(
        "materials.png",
        5,
        2,
        128,
        104,
        "center",
        "32%",
        (
            "material_clear",
            "material_rain",
            "material_cloudy",
            "material_windy",
            "material_cold",
            "material_warm",
            "material_dense",
            "material_dynamic",
            "material_stable",
            "material_sparse",
        ),
    ),
    Pack(
        "overlays.png",
        4,
        2,
        256,
        220,
        "center",
        "32%",
        (
            "overlay_rain",
            "overlay_fog",
            "overlay_snow",
            "overlay_wind",
            "overlay_dawn",
            "overlay_morning",
            "overlay_evening",
            "overlay_night",
        ),
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


def cell_bounds(length: int, count: int, index: int) -> tuple[int, int]:
    start = round(length * index / count)
    end = round(length * (index + 1) / count)
    return start, end


def run_magick(*arguments: str) -> None:
    subprocess.run(("magick", *arguments), check=True)


def process() -> None:
    if shutil.which("magick") is None:
        raise SystemExit("ImageMagick is required to process generated art")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # Other versioned authoring packs may install additional root sprites.
    # This processor owns only PACKS and must not remove their outputs.

    assets: list[dict[str, object]] = []
    sources: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="locus-art-") as raw_tmp:
        temporary = Path(raw_tmp)
        for pack in PACKS:
            source = SOURCES / pack.source
            if not source.exists():
                raise SystemExit(f"Missing source sheet: {source}")
            width, height, _ = png_contract(source)
            sources.append(
                {
                    "path": source.relative_to(ROOT).as_posix(),
                    "sha256": sha256(source),
                    "width": width,
                    "height": height,
                }
            )
            keyed = temporary / f"keyed-{pack.source}"
            run_magick(
                str(source),
                "-alpha",
                "on",
                "-fuzz",
                pack.key_fuzz,
                "-transparent",
                "#FF00FF",
                str(keyed),
            )
            for index, name in enumerate(pack.names):
                column = index % pack.columns
                row = index // pack.columns
                left, right = cell_bounds(width, pack.columns, column)
                top, bottom = cell_bounds(height, pack.rows, row)
                output = OUTPUT / f"{name}.png"
                run_magick(
                    str(keyed),
                    "-crop",
                    f"{right - left}x{bottom - top}+{left}+{top}",
                    "+repage",
                    "-trim",
                    "+repage",
                    "-filter",
                    "point",
                    "-resize",
                    f"{pack.content}x{pack.content}>",
                    "-gravity",
                    pack.gravity,
                    "-background",
                    "none",
                    "-extent",
                    f"{pack.canvas}x{pack.canvas}",
                    "-define",
                    "png:color-type=6",
                    str(output),
                )
                out_width, out_height, color_type = png_contract(output)
                assets.append(
                    {
                        "name": name,
                        "path": output.relative_to(ROOT).as_posix(),
                        "pack": Path(pack.source).stem,
                        "sourceCell": index,
                        "width": out_width,
                        "height": out_height,
                        "pngColorType": color_type,
                        "sha256": sha256(output),
                    }
                )

    payload = {
        "schemaVersion": 1,
        "package": "locus-art-v1",
        "generator": "OpenAI built-in image_gen",
        "styleReference": "assets/branding/candidates/locus-app-icon-pro-2026-08-09-1024.png",
        "chromaKey": "#FF00FF",
        "sources": sorted(sources, key=lambda item: str(item["path"])),
        "assets": sorted(assets, key=lambda item: str(item["name"])),
    }
    MANIFEST.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    validate()


def validate() -> None:
    if not MANIFEST.exists():
        raise SystemExit(f"Missing art manifest: {MANIFEST}")
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    expected = {name for pack in PACKS for name in pack.names}
    assets = payload.get("assets", [])
    actual = {item["name"] for item in assets}
    if actual != expected:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        raise SystemExit(f"Art inventory mismatch: missing={missing}, extra={extra}")
    for item in (*payload.get("sources", []), *assets):
        path = ROOT / item["path"]
        if not path.exists():
            raise SystemExit(f"Missing art file: {path}")
        width, height, color_type = png_contract(path)
        if width != item["width"] or height != item["height"]:
            raise SystemExit(f"Dimension mismatch: {path}")
        if "pngColorType" in item and color_type != 6:
            raise SystemExit(f"Asset must be RGBA PNG: {path}")
        if sha256(path) != item["sha256"]:
            raise SystemExit(f"Hash mismatch: {path}")
    installed = {path.stem for path in OUTPUT.glob("*.png")}
    if not expected.issubset(installed):
        raise SystemExit("Installed generated-art inventory is missing v1 assets")
    print(f"generated art validation passed ({len(expected)} assets)")


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
