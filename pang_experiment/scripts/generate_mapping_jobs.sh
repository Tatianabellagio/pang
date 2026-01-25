#!/bin/bash
set -euo pipefail

BASE=~/scratch/pang/pang_experiment
SCRIPT_DIR=$BASE/scripts
PANG_DIR=$BASE/pangenomes

SAMPLES=(S1 S2 S3 S4 S5 S6 S7 S8)

for SETDIR in $PANG_DIR/set_*; do
  SET_NAME=$(basename $SETDIR)

  # only generate jobs if the pangenome exists
  if [[ ! -f $SETDIR/output/${SET_NAME}.gbz ]]; then
    echo "⚠ Skipping $SET_NAME (no GBZ yet)"
    continue
  fi

  for SAMPLE in "${SAMPLES[@]}"; do
    OUT=$SCRIPT_DIR/map_${SET_NAME}_${SAMPLE}.sh

    sed \
      -e "s/MAP_SET_SAMPLE/map_${SET_NAME}_${SAMPLE}/g" \
      -e "s/SET_NAME_HERE/${SET_NAME}/g" \
      -e "s/SAMPLE_HERE/${SAMPLE}/g" \
      $SCRIPT_DIR/sbatch_map_seedmix_template.sh \
      > $OUT

    chmod +x $OUT
    echo "sbatch $OUT"
  done
done
