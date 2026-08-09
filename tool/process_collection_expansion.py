#!/usr/bin/env python3
"""Build and validate the large Locus collection-expansion art pack."""

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
PACKAGE = ROOT / "artifacts/imagegen/locus-collection-expansion-v1"
SOURCES = PACKAGE / "sources"
BASE_OUTPUT = ROOT / "assets/art/generated/v1"
DIRECTIONAL_OUTPUT = BASE_OUTPUT / "directional"
CONSTRUCTION_OUTPUT = BASE_OUTPUT / "construction"
MANIFEST = PACKAGE / "manifest.json"
CONTACT_SHEET = PACKAGE / "contact-sheet.png"


@dataclass(frozen=True)
class ObjectPack:
    name: str
    objects: tuple[str, ...]


OBJECT_PACKS = (
    ObjectPack(
        "street",
        (
            "mailbox",
            "rain_shelter",
            "stone_gate",
            "clock_post",
            "book_kiosk",
            "laundry_line",
        ),
    ),
    ObjectPack(
        "garden",
        (
            "flower_arch",
            "bird_bath",
            "greenhouse",
            "fountain",
            "picnic_table",
            "willow",
        ),
    ),
    ObjectPack(
        "night-market",
        (
            "lantern_string",
            "wind_chime",
            "tea_table",
            "market_stall",
            "stone_lantern",
            "observatory",
        ),
    ),
)

VISITOR_SHEETS = (
    (
        "visitors-a.png",
        (
            "sparrow_pair",
            "rain_frog",
            "letter_carrier",
            "window_fox",
            "tea_mouse",
            "wind_sprite",
        ),
    ),
    (
        "visitors-b.png",
        (
            "garden_keeper",
            "brook_heron",
            "book_collector",
            "night_watcher",
            "shelter_dog",
            "rooftop_swallow",
        ),
    ),
)

DIRECTIONS = ("ne", "se", "sw", "nw")
STAGES = (
    ("foundation", 0.25),
    ("frame", 0.60),
    ("finish", 0.85),
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
    return round(length * index / count), round(length * (index + 1) / count)


def run_magick(*arguments: str) -> None:
    subprocess.run(("magick", *arguments), check=True)


def crop_sprite(
    keyed: Path,
    output: Path,
    *,
    columns: int,
    rows: int,
    column: int,
    row: int,
    canvas: int,
    content: int,
) -> None:
    width, height, _ = png_contract(keyed)
    left, right = cell_bounds(width, columns, column)
    top, bottom = cell_bounds(height, rows, row)
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
        f"{content}x{content}>",
        "-gravity",
        "south",
        "-background",
        "none",
        "-extent",
        f"{canvas}x{canvas}",
        "-define",
        "png:color-type=6",
        str(output),
    )


def asset_record(
    name: str,
    path: Path,
    source: Path,
    source_cell: int,
    **metadata: object,
) -> dict[str, object]:
    width, height, color_type = png_contract(path)
    return {
        "name": name,
        "path": path.relative_to(ROOT).as_posix(),
        "source": source.relative_to(ROOT).as_posix(),
        "sourceCell": source_cell,
        "width": width,
        "height": height,
        "pngColorType": color_type,
        "sha256": sha256(path),
        **metadata,
    }


def process() -> None:
    if shutil.which("magick") is None:
        raise SystemExit("ImageMagick is required to process collection art")
    for output in (BASE_OUTPUT, DIRECTIONAL_OUTPUT, CONSTRUCTION_OUTPUT):
        output.mkdir(parents=True, exist_ok=True)

    sources: list[dict[str, object]] = []
    assets: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="locus-collection-") as raw_tmp:
        temporary = Path(raw_tmp)
        for pack in OBJECT_PACKS:
            directional_source = SOURCES / f"directional-{pack.name}.png"
            construction_source = SOURCES / f"construction-{pack.name}.png"
            for source in (directional_source, construction_source):
                width, height, _ = png_contract(source)
                sources.append(
                    {
                        "path": source.relative_to(ROOT).as_posix(),
                        "width": width,
                        "height": height,
                        "sha256": sha256(source),
                    }
                )

            keyed_directional = temporary / f"directional-{pack.name}.png"
            keyed_construction = temporary / f"construction-{pack.name}.png"
            for source, keyed in (
                (directional_source, keyed_directional),
                (construction_source, keyed_construction),
            ):
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

            for row, object_name in enumerate(pack.objects):
                for rotation, direction in enumerate(DIRECTIONS):
                    name = f"object_{object_name}_r{rotation}"
                    output = DIRECTIONAL_OUTPUT / f"{name}.png"
                    crop_sprite(
                        keyed_directional,
                        output,
                        columns=4,
                        rows=6,
                        column=rotation,
                        row=row,
                        canvas=256,
                        content=224,
                    )
                    assets.append(
                        asset_record(
                            name,
                            output,
                            directional_source,
                            row * 4 + rotation,
                            type="directional",
                            object=object_name,
                            rotation=rotation,
                            direction=direction,
                        )
                    )
                    if rotation == 0:
                        base_name = f"object_{object_name}"
                        base_output = BASE_OUTPUT / f"{base_name}.png"
                        shutil.copyfile(output, base_output)
                        assets.append(
                            asset_record(
                                base_name,
                                base_output,
                                directional_source,
                                row * 4,
                                type="base",
                                object=object_name,
                            )
                        )

                for stage_index, (stage, completion) in enumerate(STAGES):
                    name = f"construction_{object_name}_{stage}"
                    output = CONSTRUCTION_OUTPUT / f"{name}.png"
                    crop_sprite(
                        keyed_construction,
                        output,
                        columns=3,
                        rows=6,
                        column=stage_index,
                        row=row,
                        canvas=256,
                        content=224,
                    )
                    assets.append(
                        asset_record(
                            name,
                            output,
                            construction_source,
                            row * 3 + stage_index,
                            type="construction",
                            object=object_name,
                            stage=stage,
                            representativeCompletion=completion,
                        )
                    )

        for source_name, visitors in VISITOR_SHEETS:
            source = SOURCES / source_name
            width, height, _ = png_contract(source)
            sources.append(
                {
                    "path": source.relative_to(ROOT).as_posix(),
                    "width": width,
                    "height": height,
                    "sha256": sha256(source),
                }
            )
            keyed = temporary / source_name
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
            for index, visitor_id in enumerate(visitors):
                name = f"visitor_{visitor_id}"
                output = BASE_OUTPUT / f"{name}.png"
                crop_sprite(
                    keyed,
                    output,
                    columns=3,
                    rows=2,
                    column=index % 3,
                    row=index // 3,
                    canvas=192,
                    content=168,
                )
                assets.append(
                    asset_record(
                        name,
                        output,
                        source,
                        index,
                        type="visitor",
                        visitor=visitor_id,
                    )
                )

    payload = {
        "schemaVersion": 1,
        "package": "locus-collection-expansion-v1",
        "generator": "OpenAI built-in image_gen",
        "styleReferences": [
            "artifacts/imagegen/locus-directional-art-v1/contact-sheet.png",
            "artifacts/imagegen/locus-construction-art-v1/contact-sheet.png",
            "artifacts/imagegen/locus-art-v1/sources/visitors.png",
        ],
        "chromaKey": "#FF00FF",
        "directions": list(DIRECTIONS),
        "stages": [stage for stage, _ in STAGES],
        "sources": sorted(sources, key=lambda item: str(item["path"])),
        "assets": sorted(assets, key=lambda item: str(item["name"])),
    }
    MANIFEST.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    _build_contact_sheet()
    validate()


def _build_contact_sheet() -> None:
    ordered = [
        *(
            BASE_OUTPUT / f"object_{name}.png"
            for pack in OBJECT_PACKS
            for name in pack.objects
        ),
        *(
            BASE_OUTPUT / f"visitor_{visitor}.png"
            for _, visitors in VISITOR_SHEETS
            for visitor in visitors
        ),
    ]
    with tempfile.TemporaryDirectory(prefix="locus-collection-contact-") as raw_tmp:
        temporary = Path(raw_tmp)
        thumbnails: list[Path] = []
        for index, source in enumerate(ordered):
            thumbnail = temporary / f"{index:02d}.png"
            run_magick(
                str(source),
                "-filter",
                "point",
                "-resize",
                "128x128",
                "-gravity",
                "center",
                "-background",
                "#06131D",
                "-extent",
                "144x144",
                str(thumbnail),
            )
            thumbnails.append(thumbnail)
        rows: list[Path] = []
        for row in range(5):
            output = temporary / f"row-{row}.png"
            run_magick(
                *(str(path) for path in thumbnails[row * 6 : row * 6 + 6]),
                "+append",
                str(output),
            )
            rows.append(output)
        run_magick(*(str(path) for path in rows), "-append", str(CONTACT_SHEET))


def validate() -> None:
    if not MANIFEST.exists():
        raise SystemExit(f"Missing collection manifest: {MANIFEST}")
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    object_names = {name for pack in OBJECT_PACKS for name in pack.objects}
    visitor_names = {visitor for _, visitors in VISITOR_SHEETS for visitor in visitors}
    expected = {
        *(f"object_{name}" for name in object_names),
        *(f"object_{name}_r{rotation}" for name in object_names for rotation in range(4)),
        *(
            f"construction_{name}_{stage}"
            for name in object_names
            for stage, _ in STAGES
        ),
        *(f"visitor_{name}" for name in visitor_names),
    }
    assets = payload.get("assets", [])
    actual = {str(item["name"]) for item in assets}
    if actual != expected:
        raise SystemExit(
            f"Collection inventory mismatch: missing={sorted(expected - actual)}, "
            f"extra={sorted(actual - expected)}"
        )
    directional_hashes: dict[str, set[str]] = {}
    construction_hashes: dict[str, set[str]] = {}
    for item in (*payload.get("sources", []), *assets):
        path = ROOT / str(item["path"])
        if not path.is_file():
            raise SystemExit(f"Missing collection art file: {path}")
        width, height, color_type = png_contract(path)
        if width != item["width"] or height != item["height"]:
            raise SystemExit(f"Dimension mismatch: {path}")
        if "pngColorType" in item and color_type != 6:
            raise SystemExit(f"Collection runtime asset must be RGBA: {path}")
        if sha256(path) != item["sha256"]:
            raise SystemExit(f"Hash mismatch: {path}")
        if item.get("type") == "directional":
            directional_hashes.setdefault(str(item["object"]), set()).add(
                str(item["sha256"])
            )
        if item.get("type") == "construction":
            construction_hashes.setdefault(str(item["object"]), set()).add(
                str(item["sha256"])
            )
    if set(directional_hashes) != object_names or any(
        len(hashes) != 4 for hashes in directional_hashes.values()
    ):
        raise SystemExit("Every expanded object needs four distinct directions")
    if set(construction_hashes) != object_names or any(
        len(hashes) != 3 for hashes in construction_hashes.values()
    ):
        raise SystemExit("Every expanded object needs three distinct stages")
    if not CONTACT_SHEET.is_file():
        raise SystemExit(f"Missing collection contact sheet: {CONTACT_SHEET}")
    print(f"collection expansion validation passed ({len(expected)} assets)")


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
