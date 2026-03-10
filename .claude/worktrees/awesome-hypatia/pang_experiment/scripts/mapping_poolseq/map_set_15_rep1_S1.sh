#!/bin/bash
#SBATCH --job-name=map_set_15_rep1_S1
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=08:00:00
#SBATCH --output=map_set_15_rep1_S1.%j.out
#SBATCH --error=map_set_15_rep1_S1.%j.err

set -euo pipefail

# =========================
# Load environment
# =========================
eval "$(conda shell.bash hook)"

# 🔑 FIX: ensure PYTHONPATH is defined (prevents cactus env crash)
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate pang

# =========================
# Parameters (filled in)
# =========================
SET_NAME=set_15_rep1
SAMPLE=S1
THREADS=16

# =========================
# Run mapping
# =========================
~/scratch/pang/pang_experiment/scripts/mapping_poolseq/map_seedmix_to_pangenome.sh \
  $SET_NAME \
  $SAMPLE \
  $THREADS
