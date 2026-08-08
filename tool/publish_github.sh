#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VISIBILITY="${1:-public}"
OWNER="${GITHUB_OWNER:-eiranotes}"
REPOSITORY="${GITHUB_REPOSITORY_NAME:-Locus}"
FULL_NAME="$OWNER/$REPOSITORY"
GITHUB_REMOTE="https://github.com/$FULL_NAME.git"

case "$VISIBILITY" in
  private|public) ;;
  *)
    echo "usage: $0 [private|public]" >&2
    exit 2
    ;;
esac

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required. Install gh, then run: gh auth login" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi
gh auth setup-git >/dev/null

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This directory is not a git repository." >&2
  exit 1
fi

BRANCH="$(git branch --show-current)"
if [[ -z "$BRANCH" ]]; then
  echo "The repository has no current branch." >&2
  exit 1
fi

prepare_origin() {
  if ! git remote get-url origin >/dev/null 2>&1; then
    return
  fi

  local current
  current="$(git remote get-url origin)"
  case "$current" in
    "git@github.com:$FULL_NAME.git"|"https://github.com/$FULL_NAME.git"|"https://github.com/$FULL_NAME")
      return
      ;;
  esac

  if ! git remote get-url source-bundle >/dev/null 2>&1; then
    git remote rename origin source-bundle
  else
    git remote remove origin
  fi
}

prepare_origin

if gh repo view "$FULL_NAME" >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$GITHUB_REMOTE"
  else
    git remote add origin "$GITHUB_REMOTE"
  fi
  git push -u origin "$BRANCH"
else
  gh repo create "$FULL_NAME" "--$VISIBILITY" --source=. --remote=origin --push \
    --description "Reality collection and pixel diorama crafting game for iOS and Android, built with Flutter."
fi

echo "Published $FULL_NAME from branch $BRANCH"
