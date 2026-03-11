#!/bin/bash -l
#SBATCH --job-name=freqk_index
#SBATCH --output=logs/06_freqk_index_%j.out
#SBATCH --error=logs/06_freqk_index_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
# =============================================================================
# 06_freqk_index.sh
# Purpose: Build freqk k-mer index for the simulated 1kb deletion VCF
# =============================================================================
set -euo pipefail
eval "$(conda shell.bash hook)"
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}
conda activate freqk_build

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
WORK=/home/tbellagio/scratch/pang/visor_freqk
FASTA=${WORK}/data/reference/Chr1.fa
VCF=${WORK}/data/vcf/del_1kb.vcf.gz
K=31
OUT=${WORK}/results/del_1kb.k${K}.freqk.index

mkdir -p ${WORK}/results

[[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai" >&2; exit 1; }
[[ -s "$VCF"   && -s "${VCF}.tbi"   ]] || { echo "Missing VCF or tbi"  >&2; exit 1; }

echo "[$(date)] Building freqk index (k=${K})"
$FREQK index --fasta "$FASTA" --vcf "$VCF" --output "$OUT" --kmer "$K"

echo "[$(date)] Done."
ls -lh "$OUT"