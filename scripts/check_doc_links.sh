#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docs_root="${project_root}/docs"

if [[ ! -d "$docs_root" ]]; then
  echo "docs directory not found: $docs_root"
  exit 1
fi

has_error=0

while IFS= read -r file; do
  while IFS= read -r line; do
    link="${line#*:}"
    source_file="${line%%:*}"

    # ignore external URLs, anchors, and mail links
    if [[ "$link" =~ ^https?:// ]] || [[ "$link" =~ ^# ]] || [[ "$link" =~ ^mailto: ]]; then
      continue
    fi

    target_path="${link%%#*}"
    resolved_path="$(dirname "$source_file")/$target_path"

    if [[ ! -e "$resolved_path" ]]; then
      echo "Missing link target: $target_path"
      echo "  from: $source_file"
      has_error=1
    fi
  done < <(
    perl -nle 'while(/\[[^\]]+\]\(([^)]+)\)/g){print "$ARGV:$1"}' "$file"
  )
done < <(find "$docs_root" -type f -name '*.md' | sort)

if [[ "$has_error" -ne 0 ]]; then
  exit 1
fi

echo "All docs links are valid."
