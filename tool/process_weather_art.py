#!/usr/bin/env python3
"""Build and validate the bounded Locus weather-treatment layer pack."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "artifacts/imagegen/locus-weather-treatments-v1"
SOURCES = PACKAGE / "sources"
OUTPUT = ROOT / "assets/art/generated/v1/weather"
MANIFEST = PACKAGE / "manifest.json"
CONTACT_SHEET = PACKAGE / "contact-sheet.png"
KINDS = ("clear", "rain", "cloudy", "windy", "cold", "warm")
LAYERS = (
    ("surface", "surface-treatments.png"),
    ("footprint", "footprint-effects.png"),
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


def expected_names() -> set[str]:
    return {f"{layer}_{kind}" for layer, _ in LAYERS for kind in KINDS}


def process() -> None:
    if shutil.which("magick") is None:
        raise SystemExit("ImageMagick is required to process weather art")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for stale in OUTPUT.glob("*.png"):
        if stale.stem not in expected_names():
            stale.unlink()

    assets: list[dict[str, object]] = []
    sources: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="locus-weather-art-") as raw_tmp:
        temporary = Path(raw_tmp)
        for layer, filename in LAYERS:
            source = SOURCES / filename
            width, height, _ = png_contract(source)
            if (width, height) != (1536, 1024):
                raise SystemExit(f"Unexpected weather atlas dimensions: {source}")
            sources.append(
                {
                    "path": source.relative_to(ROOT).as_posix(),
                    "sha256": sha256(source),
                    "width": width,
                    "height": height,
                }
            )
            keyed = temporary / f"keyed-{filename}"
            run_magick(
                str(source),
                "-alpha",
                "on",
                "-fuzz",
                "28%",
                "-transparent",
                "#FF00FF",
                str(keyed),
            )
            for index, kind in enumerate(KINDS):
                row, column = divmod(index, 3)
                left, right = cell_bounds(width, 3, column)
                top, bottom = cell_bounds(height, 2, row)
                name = f"{layer}_{kind}"
                output = OUTPUT / f"{name}.png"
                common = (
                    str(keyed),
                    "-crop",
                    f"{right - left}x{bottom - top}+{left}+{top}",
                    "+repage",
                )
                if layer == "surface":
                    run_magick(
                        *common,
                        "-filter",
                        "point",
                        "-resize",
                        "128x128!",
                        "-define",
                        "png:color-type=6",
                        str(output),
                    )
                else:
                    run_magick(
                        *common,
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
                        "kind": kind,
                        "layer": layer,
                        "path": output.relative_to(ROOT).as_posix(),
                        "source": source.relative_to(ROOT).as_posix(),
                        "sourceCell": index,
                        "width": out_width,
                        "height": out_height,
                        "pngColorType": color_type,
                        "sha256": sha256(output),
                    }
                )

    MANIFEST.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "package": "locus-weather-treatments-v1",
                "generator": "OpenAI built-in image_gen",
                "styleReference": "artifacts/imagegen/locus-directional-art-v1/contact-sheet.png",
                "chromaKey": "#FF00FF",
                "chromaKeyFuzz": "28%",
                "kinds": list(KINDS),
                "sources": sorted(sources, key=lambda item: str(item["path"])),
                "assets": sorted(assets, key=lambda item: str(item["name"])),
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    with tempfile.TemporaryDirectory(prefix="locus-weather-contact-") as raw_tmp:
        contact_tmp = Path(raw_tmp)
        rows: list[str] = []
        for row, layer in enumerate(("surface", "footprint")):
            cells: list[str] = []
            for column, kind in enumerate(KINDS):
                cell = contact_tmp / f"{row}-{column}.png"
                run_magick(
                    str(OUTPUT / f"{layer}_{kind}.png"),
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
                    str(cell),
                )
                cells.append(str(cell))
            row_path = contact_tmp / f"row-{row}.png"
            run_magick(*cells, "+append", str(row_path))
            rows.append(str(row_path))
        run_magick(*rows, "-append", str(CONTACT_SHEET))
    validate()


def validate() -> None:
    if not MANIFEST.exists():
        raise SystemExit(f"Missing weather art manifest: {MANIFEST}")
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = payload.get("assets", [])
    expected = expected_names()
    actual = {item["name"] for item in assets}
    if actual != expected:
        raise SystemExit(
            f"Weather art inventory mismatch: missing={sorted(expected - actual)}, extra={sorted(actual - expected)}"
        )
    for item in (*payload.get("sources", []), *assets):
        path = ROOT / item["path"]
        if not path.exists():
            raise SystemExit(f"Missing weather art file: {path}")
        width, height, color_type = png_contract(path)
        if (width, height) != (item["width"], item["height"]):
            raise SystemExit(f"Dimension mismatch: {path}")
        if "pngColorType" in item and color_type != 6:
            raise SystemExit(f"Weather asset must be RGBA PNG: {path}")
        if sha256(path) != item["sha256"]:
            raise SystemExit(f"Hash mismatch: {path}")
    installed = {path.stem for path in OUTPUT.glob("*.png")}
    if installed != expected:
        raise SystemExit("Installed weather-art inventory is not exact")
    if not CONTACT_SHEET.exists():
        raise SystemExit(f"Missing weather contact sheet: {CONTACT_SHEET}")
    print(f"weather art validation passed ({len(expected)} assets)")


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
