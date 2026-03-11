#!/bin/bash -l
#SBATCH --job-name=freqk_index_all
#SBATCH --output=logs/06_freqk_index_all_%j.out
#SBATCH --error=logs/06_freqk_index_all_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=04:00:00
# =============================================================================
# 06_freqk_index_all.sh
# Purpose: Build freqk k-mer index for each deletion-size VCF
# =============================================================================
set -euo pipefail
eval "$(conda shell.bash hook)"
conda activate freqk_build

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
WORK=/home/tbellagio/scratch/pang/visor_freqk
FASTA=${WORK}/data/reference/Chr1.fa
VCF_DIR=${WORK}/data/vcf
K=31

mkdir -p ${WORK}/results

SIZES=("100bp" "500bp" "1kb" "5kb" "10kb")

for SIZE in "${SIZES[@]}"; do
  VCF=${VCF_DIR}/del_${SIZE}.vcf.gz
  OUT=${WORK}/results/del_${SIZE}.k${K}.freqk.index

  [[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai" >&2; exit 1; }
  [[ -s "$VCF"   && -s "${VCF}.tbi"   ]] || { echo "Missing VCF or tbi for ${SIZE}"  >&2; continue; }

  echo "[$(date)] Building freqk index (k=${K}) for ${SIZE}"
  $FREQK index --fasta "$FASTA" --vcf "$VCF" --output "$OUT" --kmer "$K"
  ls -lh "$OUT"
done