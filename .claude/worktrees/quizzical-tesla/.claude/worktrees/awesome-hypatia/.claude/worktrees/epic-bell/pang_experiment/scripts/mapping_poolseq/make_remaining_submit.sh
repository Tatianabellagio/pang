#!/usr/bin/env bash
set -euo pipefail

# Base experiment dir (edit if needed)
BASE="${BASE:-$HOME/scratch/pang/pang_experiment}"
PANG_DIR="$BASE/pangenomes"

IN="${1:-submit_mapping.sh}"
OUT="${2:-submit_mapping_remaining.sh}"

mkdir -p "$(dirname "$OUT")" 2>/dev/null || true

missing=0
done=0
total=0
badname=0

: > "$OUT"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  if [[ "$line" =~ ^[[:space:]]*sbatch[[:space:]]+([^[:space:]]+) ]]; then
    script_path="${BASH_REMATCH[1]}"
    script_base="$(basename "$script_path")"
    script_name="${script_base%.sh}"

    ((++total))

    # Parse set + sample from "map_<set>_<sample>"
    # Example: map_set_02_rep1_S1 -> set_02_rep1 + S1
    if [[ "$script_name" =~ ^map_(set_.*)_((S|seed)[A-Za-z0-9]+)$ ]]; then
      set_name="${BASH_REMATCH[1]}"
      sample="${BASH_REMATCH[2]}"
    else
      echo "WARN: couldn't parse set/sample from: $script_name (keeping line)" >&2
      echo "$line" >> "$OUT"
      ((++badname))
      continue
    fi

    gam="$PANG_DIR/$set_name/mapping/seedmix/$sample/$sample.gam"

    if [[ -s "$gam" ]]; then
      ((++done))
      continue
    else
      echo "$line" >> "$OUT"
      ((++missing))
    fi
  fi
done < "$IN"

echo "Wrote: $OUT"
echo "Total sbatch lines checked: $total"
echo "Already done (.gam exists): $done"
echo "Remaining (missing .gam): $missing"
echo "Unparsed (kept just in case): $badname"
