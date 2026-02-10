#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <simulator_udid> [log_file]"
  exit 1
fi

simulator_udid="$1"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run_date="$(date +%F)"
timestamp="$(date +%Y%m%d_%H%M%S)"
default_log_file="$project_root/docs/simulator_run_log_${run_date}_${timestamp}.txt"
log_file="${2:-$default_log_file}"

mkdir -p "$(dirname "$log_file")"

run_case() {
  local label="$1"
  shift

  echo "[${run_date}] START ${label}" | tee -a "$log_file"
  if "$@" >>"$log_file" 2>&1; then
    echo "[${run_date}] PASS  ${label}" | tee -a "$log_file"
  else
    echo "[${run_date}] FAIL  ${label}" | tee -a "$log_file"
    exit 1
  fi
}

skip_case() {
  local label="$1"
  local reason="$2"
  echo "[${run_date}] SKIP  ${label} (${reason})" | tee -a "$log_file"
}

run_case "boot simulator" xcrun simctl bootstatus "$simulator_udid" -b

gpx_files=(
  "Commute_In.gpx"
  "Commute_Out.gpx"
  "Pass_By.gpx"
  "Short_Stay.gpx"
  "GPS_Drift.gpx"
  "Multiple_Visits.gpx"
  "Boundary_Edge.gpx"
  "Fast_Transit.gpx"
  "Late_Night.gpx"
)

for gpx in "${gpx_files[@]}"; do
  run_case "$gpx" "$project_root/scripts/run_simulator_gpx.sh" "$simulator_udid" "$project_root/SimulatedLocations/$gpx"
done

echo "[${run_date}] DONE GPX suite" | tee -a "$log_file"
skip_case "T-004 app kill behavior" "requires physical device validation"

run_case \
  "T-012 permission downgrade integration test" \
  xcodebuild \
  -project "$project_root/GeoKintai.xcodeproj" \
  -scheme GeoKintaiApp \
  -destination "id=$simulator_udid" \
  -only-testing:GeoKintaiAppTests/AppStoreIntegrationTests/testAppStore_whenPermissionDowngraded_stopsMonitoringAndPreventsAutoRecord \
  test

run_case \
  "T-013 failure safety unit test" \
  swift test \
  --package-path "$project_root" \
  --filter test_failureHandling_whenLocationUnavailable_preservesDataAndRetries

run_case \
  "T-001 domain integration test" \
  swift test \
  --package-path "$project_root" \
  --filter test_attendanceFlow_whenInsideFor5Minutes_createsAttendanceAndProof

run_case \
  "T-002 domain integration test" \
  swift test \
  --package-path "$project_root" \
  --filter test_attendanceFlow_whenOutside2MinutesAfterExit_closesRecordAndSavesProof

run_case \
  "T-003 domain integration test" \
  swift test \
  --package-path "$project_root" \
  --filter test_attendanceFlow_whenLeaveBefore5Minutes_doesNotCreateAttendance

run_case \
  "T-005 short stay domain integration test" \
  swift test \
  --package-path "$project_root" \
  --filter test_attendanceFlow_whenLeaveBefore5Minutes_doesNotCreateAttendance

run_case \
  "T-006 verifier test" \
  swift test \
  --package-path "$project_root" \
  --filter test_exitVerifier_whenReturnInsideDuringRecheck_resetsCountdown

run_case \
  "T-007 domain integration test" \
  swift test \
  --package-path "$project_root" \
  --filter test_attendanceFlow_whenMultipleWorkplaces_tracksStateIndependently

run_case \
  "T-008 verifier test" \
  swift test \
  --package-path "$project_root" \
  --filter test_stayVerifier_whenInsideFor5Minutes_returnsConfirmed

run_case \
  "T-009 verifier test" \
  swift test \
  --package-path "$project_root" \
  --filter test_stayVerifier_whenExitBefore5Minutes_returnsCancelled

run_case \
  "T-010 verifier test" \
  swift test \
  --package-path "$project_root" \
  --filter test_timeZoneConversion_whenDisplay_convertsToTargetTimeZone

run_case \
  "T-011 multiple workplace routing test" \
  swift test \
  --package-path "$project_root" \
  --filter test_regionRouter_whenMultipleBindings_routesToCorrectWorkplace

echo "[${run_date}] DONE full simulator suite" | tee -a "$log_file"
echo "Log file: $log_file"
