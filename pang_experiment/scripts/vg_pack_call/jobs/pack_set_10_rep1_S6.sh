#!/bin/bash -l
#SBATCH --job-name=pack_set_10_rep1_S6
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --export=ALL
#SBATCH --output=pack_set_10_rep1_S6.%j.out
#SBATCH --error=pack_set_10_rep1_S6.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"

export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate pang

START_TS=$(date +%s)
echo "▶ START: $(date)"

SET_NAME=set_10_rep1
SAMPLE=S6

BASE=~/scratch/pang/pang_experiment
PANG_DIR=$BASE/pangenomes/$SET_NAME

GBZ=$PANG_DIR/output/${SET_NAME}.d2.gbz
GAM=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.gam
OUT=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.pack

vg pack -x "$GBZ" -g "$GAM" -o "$OUT" -t "$SLURM_CPUS_PER_TASK" -Q 5

END_TS=$(date +%s)
echo "✅ END:   $(date)"
echo "⏱ TOTAL: $((END_TS - START_TS)) seconds"