#!/usr/bin/env python3
"""Build and validate the catalog-driven Locus directional object sprites."""

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
PACKAGE = ROOT / "artifacts/imagegen/locus-directional-art-v1"
SOURCES = PACKAGE / "sources"
OUTPUT = ROOT / "assets/art/generated/v1/directional"
MANIFEST = PACKAGE / "manifest.json"
CONTACT_SHEET = PACKAGE / "contact-sheet.png"


@dataclass(frozen=True)
class Sheet:
    source: str
    objects: tuple[str, ...]
    row_bounds: tuple[int, ...]


SHEETS = (
    Sheet(
        "objects-a.png",
        ("alley_lamp", "signpost", "planter", "bench", "stairs"),
        (0, 294, 525, 728, 921, 1122),
    ),
    Sheet(
        "objects-b.png",
        ("tree", "bus_stop", "pond", "bridge", "tower"),
        (0, 250, 507, 666, 850, 1122),
    ),
)
DIRECTIONS = ("ne", "se", "sw", "nw")


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


def expected_names() -> set[str]:
    return {
        f"object_{object_name}_r{rotation}"
        for sheet in SHEETS
        for object_name in sheet.objects
        for rotation in range(4)
    }


def process() -> None:
    if shutil.which("magick") is None:
        raise SystemExit("ImageMagick is required to process directional art")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # Additional content packs share the directional output directory. This
    # processor owns only SHEETS and must not remove their outputs.

    assets: list[dict[str, object]] = []
    sources: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="locus-directional-art-") as raw_tmp:
        temporary = Path(raw_tmp)
        for sheet in SHEETS:
            source = SOURCES / sheet.source
            width, height, _ = png_contract(source)
            sources.append(
                {
                    "path": source.relative_to(ROOT).as_posix(),
                    "sha256": sha256(source),
                    "width": width,
                    "height": height,
                }
            )
            keyed = temporary / f"keyed-{sheet.source}"
            run_magick(
                str(source),
                "-alpha",
                "on",
                "-fuzz",
                "45%",
                "-transparent",
                "#FF00FF",
                str(keyed),
            )
            for row, object_name in enumerate(sheet.objects):
                for rotation, direction in enumerate(DIRECTIONS):
                    left, right = cell_bounds(width, 4, rotation)
                    if sheet.row_bounds[-1] != height:
                        raise SystemExit(
                            f"Directional source height changed without reviewed row bounds: {source}"
                        )
                    top, bottom = sheet.row_bounds[row : row + 2]
                    name = f"object_{object_name}_r{rotation}"
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
                        "224x224>",
                        "-gravity",
                        "south",
                        "-background",
                        "none",
                        "-extent",
                        "256x256",
                        "-define",
                        "png:color-type=6",
                        str(output),
                    )
                    out_width, out_height, color_type = png_contract(output)
                    assets.append(
                        {
                            "name": name,
                            "object": object_name,
                            "rotation": rotation,
                            "direction": direction,
                            "path": output.relative_to(ROOT).as_posix(),
                            "source": source.relative_to(ROOT).as_posix(),
                            "sourceCell": row * 4 + rotation,
                            "width": out_width,
                            "height": out_height,
                            "pngColorType": color_type,
                            "sha256": sha256(output),
                        }
                    )

    payload = {
        "schemaVersion": 1,
        "package": "locus-directional-art-v1",
        "generator": "OpenAI built-in image_gen",
        "styleReference": "artifacts/imagegen/locus-art-v1/sources/objects.png",
        "chromaKey": "#FF00FF",
        "directions": list(DIRECTIONS),
        "sources": sorted(sources, key=lambda item: str(item["path"])),
        "assets": sorted(assets, key=lambda item: str(item["name"])),
    }
    MANIFEST.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    ordered = [
        OUTPUT / f"object_{name}_r{rotation}.png"
        for sheet in SHEETS
        for name in sheet.objects
        for rotation in range(4)
    ]
    with tempfile.TemporaryDirectory(prefix="locus-directional-contact-") as raw_tmp:
        contact_tmp = Path(raw_tmp)
        thumbnails: list[Path] = []
        for index, source in enumerate(ordered):
            thumbnail = contact_tmp / f"{index:02d}.png"
            run_magick(
                str(source),
                "-filter",
                "point",
                "-resize",
                "128x128",
                "-background",
                "#071522",
                "-gravity",
                "center",
                "-extent",
                "144x144",
                str(thumbnail),
            )
            thumbnails.append(thumbnail)
        rows: list[str] = []
        for row in range(10):
            row_path = contact_tmp / f"row-{row:02d}.png"
            run_magick(
                *(str(path) for path in thumbnails[row * 4 : row * 4 + 4]),
                "+append",
                str(row_path),
            )
            rows.append(str(row_path))
        run_magick(*rows, "-append", str(CONTACT_SHEET))
    validate()


def validate() -> None:
    if not MANIFEST.exists():
        raise SystemExit(f"Missing directional art manifest: {MANIFEST}")
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = payload.get("assets", [])
    expected = expected_names()
    actual = {item["name"] for item in assets}
    if actual != expected:
        raise SystemExit(
            f"Directional art inventory mismatch: missing={sorted(expected - actual)}, extra={sorted(actual - expected)}"
        )
    grouped: dict[str, set[int]] = {}
    hashes_by_object: dict[str, set[str]] = {}
    for item in (*payload.get("sources", []), *assets):
        path = ROOT / item["path"]
        if not path.exists():
            raise SystemExit(f"Missing directional art file: {path}")
        width, height, color_type = png_contract(path)
        if width != item["width"] or height != item["height"]:
            raise SystemExit(f"Dimension mismatch: {path}")
        if "pngColorType" in item and color_type != 6:
            raise SystemExit(f"Directional asset must be RGBA PNG: {path}")
        if sha256(path) != item["sha256"]:
            raise SystemExit(f"Hash mismatch: {path}")
        if "object" in item:
            object_name = str(item["object"])
            grouped.setdefault(object_name, set()).add(int(item["rotation"]))
            hashes_by_object.setdefault(object_name, set()).add(str(item["sha256"]))
    if any(rotations != {0, 1, 2, 3} for rotations in grouped.values()):
        raise SystemExit("Every directional object must have rotations 0 through 3")
    if any(len(hashes) != 4 for hashes in hashes_by_object.values()):
        raise SystemExit("Every directional object must have four distinct images")
    installed = {path.stem for path in OUTPUT.glob("*.png")}
    if not expected.issubset(installed):
        raise SystemExit("Installed directional-art inventory is missing v1 assets")
    if not CONTACT_SHEET.exists():
        raise SystemExit(f"Missing directional contact sheet: {CONTACT_SHEET}")
    print(f"directional art validation passed ({len(expected)} assets)")


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
