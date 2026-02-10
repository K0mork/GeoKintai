#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
today="$(date +%F)"
tester="${1:-TBD}"
device="${2:-TBD}"
os_version="${3:-TBD}"
output_path="${4:-$project_root/docs/real_device_run_log_${today}.md}"

if [[ -e "$output_path" ]]; then
  echo "File already exists: $output_path"
  echo "Pass a different output path as the 4th argument."
  exit 1
fi

mkdir -p "$(dirname "$output_path")"

cat >"$output_path" <<EOF
# 実機検証ログ ${today}

参照計画: [real_device_test_plan.md](real_device_test_plan.md)

## 実施情報
- 実施日: ${today}
- 実施者: ${tester}
- 端末: ${device}
- OS: ${os_version}

## 結果
| ケースID | 実施日 | 実施者 | 端末 | OS | 結果 | 逸脱内容 | 再現手順 |
|---|---|---|---|---|---|---|---|
| T-004 | ${today} | ${tester} | ${device} | ${os_version} | Pending | - | - |

## メモ
- 
EOF

echo "Created: $output_path"
