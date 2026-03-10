#!/bin/bash
#SBATCH --job-name=make_beds
#SBATCH --output=logs/01_make_beds_%j.out
#SBATCH --error=logs/01_make_beds_%j.err
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G

# =============================================================================
# 01_make_beds.sh
# Purpose: Create VISOR HACk BED files for each deletion size
# Experiment: SV size benchmark (fixed freq=0.50, coverage=50x, type=deletion)
# Deletions are placed in euchromatic region of Chr1 (10Mb, away from centromere ~15Mb)
# BED format: chrom  start  end  svtype  info  stranddev
# =============================================================================

set -euo pipefail
source $(mamba info --base)/etc/profile.d/conda.sh && conda activate pang

BEDS=/home/tbellagio/scratch/pang/visor_freqk/data/beds

mkdir -p ${BEDS}
mkdir -p logs

echo "[$(date)] Creating BED files in ${BEDS}"

echo -e "Chr1\t10000000\t10000100\tdeletion\tNone\t0" > ${BEDS}/hack_del_100bp.bed
echo -e "Chr1\t10000000\t10000500\tdeletion\tNone\t0" > ${BEDS}/hack_del_500bp.bed
echo -e "Chr1\t10000000\t10001000\tdeletion\tNone\t0" > ${BEDS}/hack_del_1kb.bed
echo -e "Chr1\t10000000\t10005000\tdeletion\tNone\t0" > ${BEDS}/hack_del_5kb.bed
echo -e "Chr1\t10000000\t10010000\tdeletion\tNone\t0" > ${BEDS}/hack_del_10kb.bed

echo "[$(date)] Done. BED files created:"
ls -lh ${BEDS}/hack_del_*.bed