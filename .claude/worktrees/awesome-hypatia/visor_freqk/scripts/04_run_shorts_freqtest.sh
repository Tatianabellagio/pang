#!/bin/bash -l
#SBATCH --job-name=visor_shorts_freq
#SBATCH --output=logs/04_run_shorts_freqtest_%j.out
#SBATCH --error=logs/04_run_shorts_freqtest_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=04:00:00
# =============================================================================
# 04_run_shorts_freqtest.sh
# Purpose: Simulate pool-seq reads for freq benchmark using VISOR SHORtS
# Design:  freq=0.50, 1kb deletion, 50x total coverage
#          2 separate clone dirs passed to -s, weighted with --clonefraction:
#            Clone 1 (_clone_DEL_1kb/h1.fa): 50% -> 25x
#            Clone 2 (_clone_WT/h1.fa):      50% -> 25x
# =============================================================================
set -euo pipefail
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
HAPS=/home/tbellagio/scratch/pang/visor_freqk/data/haplotypes
READS=/home/tbellagio/scratch/pang/visor_freqk/data/reads
BEDS=/home/tbellagio/scratch/pang/visor_freqk/data/beds

CLONE_DEL=${HAPS}/_clone_DEL_1kb
CLONE_WT=${HAPS}/_clone_WT

mkdir -p logs

# Region BED (full Chr1, 5 columns)
CHR1_LEN=$(awk '$1=="Chr1" {print $2}' "${REF}.fai")
REGION_BED="${BEDS}/shorts_region_Chr1.bed"
echo -e "Chr1\t1\t${CHR1_LEN}\t100.0\t100.0" > "${REGION_BED}"
echo "[$(date)] Region BED: Chr1 1-${CHR1_LEN}"

OUT="${READS}/freq_1kb_050"
rm -rf "${OUT}"
mkdir -p "${OUT}"

echo "[$(date)] Running VISOR SHORtS: 2 clones, freq=0.50, size=1kb, coverage=50x"

VISOR SHORtS \
    -g "${REF}" \
    -s "${CLONE_DEL}" "${CLONE_WT}" \
    -b "${REGION_BED}" \
    -o "${OUT}" \
    --coverage 50 \
    --clonefraction 50.0 50.0 \
    --fastq \
    --threads 8 || true

echo "[$(date)] Done. Output in ${OUT}"
ls -lh "${OUT}"