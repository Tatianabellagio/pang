#!/bin/bash
#SBATCH --job-name=decon_nested
#SBATCH --output=decon_nested.%j.out
#SBATCH --error=decon_nested.%j.err
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

# Clustering threshold: 1.0 is conservative (only identical traversal handle-sets).
# If you later want more merging, try 0.98 or 0.95.
CLUSTER=1.0

OUT=set_02_rep1.deconstruct.nested.L${CLUSTER}.vcf.gz
OFFREF=set_02_rep1.deconstruct.nested.L${CLUSTER}.offref.fa.gz

ls -lh "$GRAPH" "$SNARLS" >/dev/null

vg deconstruct \
  -n \
  -R \
  -L "$CLUSTER" \
  -f "$OFFREF" \
  -P "$REFPREFIX" \
  -r "$SNARLS" \
  -K \
  -t "$SLURM_CPUS_PER_TASK" \
  "$GRAPH" \
| bgzip -c > "$OUT"

tabix -f -p vcf "$OUT"

echo "Wrote: $WORKDIR/$OUT"
echo "Wrote: $WORKDIR/$OFFREF"
echo "Wrote: $WORKDIR/${OFFREF}.nesting.tsv"
