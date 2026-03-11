#!/bin/bash
#SBATCH --job-name=visor_hack
#SBATCH --output=logs/02_run_hack_%j.out
#SBATCH --error=logs/02_run_hack_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
# =============================================================================
# 02_run_hack.sh
# Purpose: Run VISOR HACk to inject homozygous deletions into Chr1
# Experiment: SV size benchmark (fixed freq=0.50, coverage=50x, type=deletion)
# Both HAP1 and HAP2 carry the deletion (homozygous, inbred Arabidopsis lines)
# Output: data/haplotypes/del_<size>/HAP1/ and HAP2/
# =============================================================================
set -euo pipefail
source $(mamba info --base)/etc/profile.d/conda.sh && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
BEDS=/home/tbellagio/scratch/pang/visor_freqk/data/beds
HAPS=/home/tbellagio/scratch/pang/visor_freqk/data/haplotypes

mkdir -p logs

declare -A SIZES=(
    ["100bp"]="hack_del_100bp.bed"
    ["500bp"]="hack_del_500bp.bed"
    ["1kb"]="hack_del_1kb.bed"
    ["5kb"]="hack_del_5kb.bed"
    ["10kb"]="hack_del_10kb.bed"
)

for SIZE in "${!SIZES[@]}"; do
    BED=${BEDS}/${SIZES[$SIZE]}
    HAP1_OUT=${HAPS}/del_${SIZE}/HAP1
    HAP2_OUT=${HAPS}/del_${SIZE}/HAP2

    mkdir -p ${HAP1_OUT} ${HAP2_OUT}

    echo "[$(date)] Running VISOR HACk for deletion size: ${SIZE}"

    # HAP1
    VISOR HACk \
        -g ${REF} \
        -b ${BED} \
        -o ${HAP1_OUT}

    # HAP2 (same BED — homozygous)
    VISOR HACk \
        -g ${REF} \
        -b ${BED} \
        -o ${HAP2_OUT}

    echo "[$(date)] Done: del_${SIZE}"
done

echo "[$(date)] All deletions processed. Haplotypes in ${HAPS}"c