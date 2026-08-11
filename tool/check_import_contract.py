#!/usr/bin/env python3
"""Validate the one-time Flutter import completion contract."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        fail(f"missing required import contract file: {relative}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    status = read("IMPORT_STATUS.md")
    complete = read("IMPORT_COMPLETE.md")
    workflow = read(".github/workflows/flutter.yml")
    reporter = read(".github/workflows/import-failure-report.yml")

    if re.search(r"^Conclusion:\s*success\s*$", status, re.MULTILINE) is None:
        fail("IMPORT_STATUS.md must contain `Conclusion: success`")
    if "IMPORT_STATUS.md" not in complete or "main" not in complete:
        fail("IMPORT_COMPLETE.md must define its main-branch validity contract")

    required_ci_fragments = (
        "push:\n    branches:\n      - main",
        "pull_request:\n    branches:\n      - main",
        "permissions:\n  contents: read",
        "python3 tool/check_repo.py",
        "python3 tool/check_import_contract.py",
        "flutter analyze",
        "flutter test",
        "flutter build apk",
        "flutter build ios --simulator",
        "needs:\n      - verify\n      - ios-compile",
    )
    for fragment in required_ci_fragments:
        if fragment not in workflow:
            fail(f"Flutter CI is missing contract fragment: {fragment!r}")

    for forbidden in ("contents: write", "git push", "git commit", "branches: ['**']"):
        if forbidden in workflow:
            fail(f"Flutter CI must remain read-only: found {forbidden!r}")

    for workflow_path in sorted((ROOT / ".github/workflows").glob("*.yml")):
        workflow_text = workflow_path.read_text(encoding="utf-8")
        for forbidden in ("contents: write", "git push", "git commit"):
            if forbidden in workflow_text:
                fail(
                    f"workflow {workflow_path.name} must not mutate source: "
                    f"found {forbidden!r}"
                )

    reporter_fragments = (
        "workflow_run:",
        'workflows: ["Flutter CI"]',
        "issues: write",
        "Flutter import requires follow-up",
        "head_branch !== 'main'",
    )
    for fragment in reporter_fragments:
        if fragment not in reporter:
            fail(f"failure reporter is missing contract fragment: {fragment!r}")

    obsolete_paths = (
        ".github/ACTIONS_HEARTBEAT",
        ".github/bootstrap-trigger",
        ".github/workflows/actions-heartbeat.yml",
        ".github/workflows/bootstrap-source-pr.yml",
        ".github/workflows/bootstrap-source.yml",
        ".github/workflows/scheduled-bootstrap-v2.yml",
        ".github/workflows/scheduled-bootstrap.yml",
        ".github/workflows/scheduled-import-validation.yml",
        "bootstrap",
    )
    remaining = [relative for relative in obsolete_paths if (ROOT / relative).exists()]
    if remaining:
        fail(f"obsolete one-shot import artifacts remain: {remaining}")

    print("import completion contract passed")


if __name__ == "__main__":
    main()
