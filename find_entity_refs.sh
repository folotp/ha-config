#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <entity_id>"
  exit 1
fi

ENTITY="$1"

# Escape regex-special chars so we match it literally
ESCAPED=$(printf '%s' "$ENTITY" | sed -e 's/[][\.*^$\/]/\\&/g')
PATTERN="\\b${ESCAPED}\\b"

# Find all YAML/JSON + UI files except the four core storage files, grep in parallel, group line numbers per file
find . -type f \
  \( \
    -path './.storage/*' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \
  \) \
  ! -path './.storage/core.area_registry' \
  ! -path './.storage/core.entity_registry' \
  ! -path './.storage/core.restore_state' \
  -print0 \
| xargs -0 -P4 -n10 grep -n -E "$PATTERN" \
| awk -F: '
    { file=$1; line=$2
      if (lines[file]=="") lines[file]=line
      else             lines[file]=lines[file] "," line
    }
    END {
      for (f in lines) print f ":" lines[f]
    }
  ' \
| sort

