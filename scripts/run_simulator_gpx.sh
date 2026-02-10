#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <simulator_udid> <gpx_file>"
  exit 1
fi

udid="$1"
gpx_file="$2"

if [[ ! -f "$gpx_file" ]]; then
  echo "GPX file not found: $gpx_file"
  exit 1
fi

xcrun simctl boot "$udid" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$udid" -b

points=()
while IFS= read -r point; do
  points+=("$point")
done < <(perl -nle 'while(/<(?:trkpt|wpt)\s+lat="([^"]+)"\s+lon="([^"]+)"/g){print "$1,$2"}' "$gpx_file")

if [[ "${#points[@]}" -eq 0 ]]; then
  echo "No location points found in GPX: $gpx_file"
  exit 1
fi

if [[ "${#points[@]}" -eq 1 ]]; then
  xcrun simctl location "$udid" set "${points[0]}"
  exit 0
fi

printf '%s\n' "${points[@]}" | xcrun simctl location "$udid" start --interval=1 -
