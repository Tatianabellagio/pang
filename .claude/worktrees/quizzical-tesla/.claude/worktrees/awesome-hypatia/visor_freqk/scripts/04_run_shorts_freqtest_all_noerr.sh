#!/bin/bash -l
#SBATCH --job-name=visor_shorts_freq_all
#SBATCH --output=logs/04_run_shorts_freqtest_all_%j.out
#SBATCH --error=logs/04_run_shorts_freqtest_all_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=04:00:00
# =============================================================================
# 04_run_shorts_freqtest_all_noerr.sh
# Purpose: Simulate pool-seq reads for freq benchmark using VISOR SHORtS
# Design:  freq=0.50, multiple deletion sizes, 50x total coverage
#          --error 0: no sequencing errors, to test if junction k-mers
#          are found perfectly by freqk (diagnostic run)
# =============================================================================
set -euo pipefail
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
HAPS=/home/tbellagio/scratch/pang/visor_freqk/data/haplotypes
READS=/home/tbellagio/scratch/pang/visor_freqk/data/reads
BEDS=/home/tbellagio/scratch/pang/visor_freqk/data/beds

# WT clone (shared across all deletion sizes)
CLONE_WT=${HAPS}/_clone_WT

mkdir -p logs

# Region BED (full Chr1, 5 columns)
CHR1_LEN=$(awk '$1=="Chr1" {print $2}' "${REF}.fai")
REGION_BED="${BEDS}/shorts_region_Chr1.bed"
echo -e "Chr1\t1\t${CHR1_LEN}\t100.0\t100.0" > "${REGION_BED}"
echo "[$(date)] Region BED: Chr1 1-${CHR1_LEN}"

SIZES=("100bp" "500bp" "1kb" "5kb" "10kb")

for SIZE in "${SIZES[@]}"; do
  # Deletion clone: use HAP1 haplotype for this deletion size
  CLONE_DEL="${HAPS}/del_${SIZE}/HAP1"

  OUT="${READS}/freq_${SIZE}_050_noerr"
  rm -rf "${OUT}"
  mkdir -p "${OUT}"

  echo "[$(date)] Running VISOR SHORtS: 2 clones, freq=0.50, size=${SIZE}, coverage=50x, error=0"

  VISOR SHORtS \
      -g "${REF}" \
      -s "${CLONE_DEL}" "${CLONE_WT}" \
      -b "${REGION_BED}" \
      -o "${OUT}" \
      --coverage 50 \
      --clonefraction 50.0 50.0 \
      --error 0 \
      --fastq \
      --threads 8 || true

  echo "[$(date)] Done. Output in ${OUT}"
  ls -lh "${OUT}"
done

