#!/bin/bash -l
#SBATCH --job-name=FQC_SITE4
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --export=ALL
#SBATCH --output=logs/FQC_SITE4.%j.out
#SBATCH --error=logs/FQC_SITE4.%j.err

set -euo pipefail
eval "$(conda shell.bash hook)"
conda activate pang

BASE=/home/tbellagio/scratch/pang/test_freqk/pilot_site4
cd "$BASE"

mkdir -p qc/fastqc_trimmed qc/multiqc_trimmed

# FastQC on paired outputs only (P reads)
fastqc -t "${SLURM_CPUS_PER_TASK}" -o qc/fastqc_trimmed trimmed/*.R1.P.fq.gz trimmed/*.R2.P.fq.gz

# Summarize
multiqc -o qc/multiqc_trimmed qc/fastqc_trimmed
