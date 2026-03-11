#!/bin/bash
#SBATCH --job-name=vg_auto_g2
#SBATCH --partition=bse
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --output=vg_auto_g2.%j.out
#SBATCH --error=vg_auto_g2.%j.err

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

WORKDIR="$HOME/scratch/pang/vg_construct"
cd "$WORKDIR"

FA="Col-0.fasta"
VCF="g2.renamed.vcf.gz"
PREFIX="col_g2"

# Run autoindex for short reads (giraffe)
vg autoindex \
  --workflow sr-giraffe \
  --prefix "$PREFIX" \
  --ref-fasta "$FA" \
  --vcf "$VCF" \
  --threads "$SLURM_CPUS_PER_TASK"

echo "Done. Outputs:"
ls -lh ${PREFIX}*
EOF