#!/bin/bash
#SBATCH --job-name=decon_top
#SBATCH --output=decon_top.%j.out
#SBATCH --error=decon_top.%j.err
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G

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

WORKDIR=/home/tbellagio/scratch/pang/pang_experiment/pangenomes/set_02_rep1/output
cd "$WORKDIR"

GRAPH=set_02_rep1.gbz
SNARLS=set_02_rep1.snarls
REFPREFIX='TAIR10'

OUT=set_02_rep1.deconstruct.top.vcf.gz

# Sanity check inputs
ls -lh "$GRAPH" "$SNARLS" >/dev/null

vg deconstruct \
  -P "$REFPREFIX" \
  -r "$SNARLS" \
  -K \
  -t "$SLURM_CPUS_PER_TASK" \
  "$GRAPH" \
| bgzip -c > "$OUT"

tabix -f -p vcf "$OUT"

echo "Wrote: $WORKDIR/$OUT"
