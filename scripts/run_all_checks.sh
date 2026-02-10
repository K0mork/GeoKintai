#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_file="$project_root/GeoKintai.xcodeproj"
scheme="GeoKintaiApp"

find_simulator_udid() {
  local preferred_device="iPhone 16"
  local udid=""

  udid="$(xcrun simctl list devices available | awk -F '[()]' -v name="$preferred_device" '$0 ~ name" \\(" { print $2; exit }')"
  if [[ -n "$udid" ]]; then
    echo "$udid"
    return 0
  fi

  udid="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { print $2; exit }')"
  if [[ -n "$udid" ]]; then
    echo "$udid"
    return 0
  fi

  return 1
}

simulator_udid="${1:-}"
if [[ -z "$simulator_udid" ]]; then
  simulator_udid="$(find_simulator_udid)" || {
    echo "No available iPhone simulator was found."
    exit 1
  }
fi

echo "[1/3] Running Swift package tests"
(cd "$project_root" && swift test)

echo "[2/3] Booting simulator: $simulator_udid"
xcrun simctl boot "$simulator_udid" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$simulator_udid" -b >/dev/null

echo "[3/3] Running Xcode app tests on simulator: $simulator_udid"
xcodebuild \
  -project "$project_file" \
  -scheme "$scheme" \
  -destination "id=$simulator_udid" \
  test

echo "All checks passed."
