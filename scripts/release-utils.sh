#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Release utils

Commands:
  promote-latest <tag>   Mark the given release tag as Latest (via gh)
  list                   List releases (tag, isLatest)

Requires:
  - gh CLI authenticated with repo access
EOF
}

cmd=${1:-}
case "$cmd" in
  promote-latest)
    tag=${2:-}
    if [ -z "$tag" ]; then
      echo "Tag required" >&2; exit 1
    fi
    gh release edit "$tag" --latest
    echo "Marked $tag as Latest"
    ;;
  list)
    gh release list --limit 100 --json tagName,isLatest --jq '.[] | "\(.tagName)\tlatest=\(.isLatest)"'
    ;;
  *)
    usage
    ;;
esac

