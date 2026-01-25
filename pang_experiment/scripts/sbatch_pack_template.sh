#!/bin/bash
#SBATCH --job-name=PACK_SET_SAMPLE
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=PACK_SET_SAMPLE.%j.out
#SBATCH --error=PACK_SET_SAMPLE.%j.err

set -eo pipefail
# 👆 NOTE: removed -u for now

# -------------------------
# Environment
# -------------------------
eval "$(conda shell.bash hook)"
conda activate pang

# now re-enable strict mode if you want
set -u

# -------------------------
# Parameters
# -------------------------
SET_NAME=SET_NAME_HERE
SAMPLE=SAMPLE_HERE
THREADS=8

# -------------------------
# Paths
# -------------------------
BASE=~/scratch/pang/pang_experiment
PANG_DIR=$BASE/pangenomes/$SET_NAME

GBZ=$PANG_DIR/output/${SET_NAME}.d2.gbz
GAM=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.gam
OUT=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.pack

# -------------------------
# Sanity checks
# -------------------------
[[ -f $GBZ ]] || { echo "❌ Missing GBZ"; exit 1; }
[[ -f $GAM ]] || { echo "❌ Missing GAM"; exit 1; }

echo "▶ Packing $SET_NAME / $SAMPLE"
date

# -------------------------
# Run pack
# -------------------------
vg pack \
  -x $GBZ \
  -g $GAM \
  -o $OUT \
  -t $THREADS

echo "✅ DONE"
date

