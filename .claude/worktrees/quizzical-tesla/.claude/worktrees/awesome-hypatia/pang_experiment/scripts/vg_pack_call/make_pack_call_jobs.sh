#!/bin/bash
set -euo pipefail

BASE=~/scratch/pang/pang_experiment
SCRIPT_DIR=$BASE/scripts/vg_pack_call
PANG_DIR=$BASE/pangenomes

PACK_TEMPLATE=$SCRIPT_DIR/pack_template.sh
CALL_TEMPLATE=$SCRIPT_DIR/call_template.sh

# where to write the generated jobs
OUT_DIR=$SCRIPT_DIR/jobs
mkdir -p "$OUT_DIR"

for SETDIR in "$PANG_DIR"/set_*; do
  SET_NAME=$(basename "$SETDIR")

  # require the graph output to exist
  if [[ ! -f "$SETDIR/output/${SET_NAME}.d2.gbz" ]]; then
    echo "⚠ Skipping $SET_NAME (no d2.gbz yet)"
    continue
  fi

  # discover samples from existing GAMs
  shopt -s nullglob
  GAMS=("$SETDIR"/mapping/seedmix/*/*.gam)
  shopt -u nullglob

  if [[ ${#GAMS[@]} -eq 0 ]]; then
    echo "⚠ Skipping $SET_NAME (no GAMs under mapping/seedmix/*/*.gam)"
    continue
  fi

  for GAM in "${GAMS[@]}"; do
    SAMPLE_DIR=$(dirname "$GAM")
    SAMPLE=$(basename "$SAMPLE_DIR")

    PACK_OUT="$OUT_DIR/pack_${SET_NAME}_${SAMPLE}.sh"
    CALL_OUT="$OUT_DIR/call_${SET_NAME}_${SAMPLE}.sh"

    sed \
      -e "s/PACK_SET_SAMPLE/pack_${SET_NAME}_${SAMPLE}/g" \
      -e "s/CALL_SET_SAMPLE/call_${SET_NAME}_${SAMPLE}/g" \
      -e "s/SET_NAME_HERE/${SET_NAME}/g" \
      -e "s/SAMPLE_HERE/${SAMPLE}/g" \
      "$PACK_TEMPLATE" > "$PACK_OUT"

    sed \
      -e "s/PACK_SET_SAMPLE/pack_${SET_NAME}_${SAMPLE}/g" \
      -e "s/CALL_SET_SAMPLE/call_${SET_NAME}_${SAMPLE}/g" \
      -e "s/SET_NAME_HERE/${SET_NAME}/g" \
      -e "s/SAMPLE_HERE/${SAMPLE}/g" \
      "$CALL_TEMPLATE" > "$CALL_OUT"

    chmod +x "$PACK_OUT" "$CALL_OUT"

    # print sbatch commands (pack then call)
    echo "PACK_JOB=\$(sbatch --parsable $PACK_OUT); sbatch --dependency=afterok:\$PACK_JOB $CALL_OUT"
  done
done
