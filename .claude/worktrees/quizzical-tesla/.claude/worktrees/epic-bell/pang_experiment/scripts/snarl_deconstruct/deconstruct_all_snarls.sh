#!/bin/bash
#SBATCH --job-name=decon_all
#SBATCH --output=decon_all.%j.out
#SBATCH --error=decon_all.%j.err
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G

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

OUT=set_02_rep1.deconstruct.all_snarls.vcf.gz

ls -lh "$GRAPH" "$SNARLS" >/dev/null

vg deconstruct \
  -a \
  -P "$REFPREFIX" \
  -r "$SNARLS" \
  -K \
  -t "$SLURM_CPUS_PER_TASK" \
  "$GRAPH" \
| bgzip -c > "$OUT"

tabix -f -p vcf "$OUT"

echo "Wrote: $WORKDIR/$OUT"
