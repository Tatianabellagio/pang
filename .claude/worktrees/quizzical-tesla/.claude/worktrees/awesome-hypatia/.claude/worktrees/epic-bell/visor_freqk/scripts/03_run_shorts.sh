#!/bin/bash
#SBATCH --job-name=visor_shorts
#SBATCH --output=logs/03_run_shorts_%j.out
#SBATCH --error=logs/03_run_shorts_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
# =============================================================================
# 03_run_shorts.sh
# Purpose: Run VISOR SHORtS to simulate Illumina reads (50x) from haplotypes
# =============================================================================

set -euo pipefail
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
HAPS=/home/tbellagio/scratch/pang/visor_freqk/data/haplotypes
READS=/home/tbellagio/scratch/pang/visor_freqk/data/reads
BEDS=/home/tbellagio/scratch/pang/visor_freqk/data/beds

mkdir -p logs "${BEDS}"

# Region BED for SHORtS (full Chr1) — 5 columns required
CHR1_LEN=$(awk '$1=="Chr1" {print $2}' "${REF}.fai")
REGION_BED="${BEDS}/shorts_region_Chr1.bed"
echo -e "Chr1\t1\t${CHR1_LEN}\t100.0\t100.0" > "${REGION_BED}"
echo "[$(date)] Region BED: Chr1 1-${CHR1_LEN} -> ${REGION_BED}"

SIZES=("100bp" "500bp" "1kb" "5kb" "10kb")

for SIZE in "${SIZES[@]}"; do
  OUT="${READS}/del_${SIZE}"
  # VISOR requires output folder to be empty (no files AND no subdirs)
  rm -rf "${OUT}"
  mkdir -p "${OUT}"

  echo "[$(date)] Running VISOR SHORtS for deletion size: ${SIZE}"

  # Make a SHORtS input dir with FASTAs at top-level (avoid overwrite: both are named h1.fa)
  SAMPLE_DIR="${HAPS}/_shorts_in_del_${SIZE}"
  mkdir -p "${SAMPLE_DIR}"
  ln -sf "${HAPS}/del_${SIZE}/HAP1/h1.fa" "${SAMPLE_DIR}/HAP1.fa"
  ln -sf "${HAPS}/del_${SIZE}/HAP2/h1.fa" "${SAMPLE_DIR}/HAP2.fa"

  VISOR SHORtS \
    -g "${REF}" \
    -s "${SAMPLE_DIR}" \
    -b "${REGION_BED}" \
    -o "${OUT}" \
    --coverage 50 \
    --fastq \
    --threads 8 || true

  echo "[$(date)] Done: del_${SIZE} -> ${OUT}"
done

echo "[$(date)] All reads simulated. Output in ${READS}"