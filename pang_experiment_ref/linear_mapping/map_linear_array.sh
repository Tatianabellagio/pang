#!/bin/bash
#SBATCH --job-name=MAP_LINEAR
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=08:00:00
#SBATCH --output=logs/MAP_LINEAR_%A_%a.out
#SBATCH --error=logs/MAP_LINEAR_%A_%a.err

set -euo pipefail

eval "$(conda shell.bash hook)"

export PYTHONPATH="${PYTHONPATH:-}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
conda activate pang

THREADS="${SLURM_CPUS_PER_TASK:-16}"

# --- EDIT THESE PATHS IF NEEDED ---
REF=~/scratch/pang/pang_experiment_ref/linear_mapping/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa

READ_DIR=~/scratch/pang/grenenet_reads/seed_mix
OUTBASE=~/scratch/pang/pang_experiment_ref/linear_mapping/results
# ---------------------------------

mkdir -p logs "$OUTBASE"

# Build a sample list from files like: S1-1.1_P.fq.gz and S1-1.2_P.fq.gz
SAMPLES_FILE="samples.txt"
if [[ ! -s "$SAMPLES_FILE" ]]; then
  ls "$READ_DIR"/*-1.1_P.fq.gz \
    | sed 's#.*/##' \
    | sed 's/-1\.1_P\.fq\.gz$//' \
    | sort -u > "$SAMPLES_FILE"
fi

N=$(wc -l < "$SAMPLES_FILE")
if [[ "${SLURM_ARRAY_TASK_ID:-}" == "" ]]; then
  echo "❌ This script must be run as a Slurm array job."
  echo "   Found $N samples in $SAMPLES_FILE. Submit like:"
  echo "   sbatch --array=1-$N map_linear_array.sh"
  exit 1
fi

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES_FILE")

OUTDIR="$OUTBASE/$SAMPLE"
mkdir -p "$OUTDIR"

R1="$READ_DIR/${SAMPLE}-1.1_P.fq.gz"
R2="$READ_DIR/${SAMPLE}-1.2_P.fq.gz"

if [[ ! -s "$R1" || ! -s "$R2" ]]; then
  echo "❌ Missing reads for $SAMPLE"
  echo "R1=$R1"
  echo "R2=$R2"
  exit 1
fi

echo "▶ Mapping $SAMPLE to TAIR10"
date
echo "REF=$REF"
echo "R1=$R1"
echo "R2=$R2"
echo "OUTDIR=$OUTDIR"
echo "THREADS=$THREADS"

# If BAM already exists + index, skip (prevents accidental rework)
if [[ -s "$OUTDIR/${SAMPLE}.sorted.bam" && -s "$OUTDIR/${SAMPLE}.sorted.bam.bai" ]]; then
  echo "✅ BAM already exists for $SAMPLE — skipping mapping."
else
  bwa-mem2 mem -t "$THREADS" "$REF" "$R1" "$R2" \
    | samtools sort -@ "$((THREADS/2))" -o "$OUTDIR/${SAMPLE}.sorted.bam"

  samtools index "$OUTDIR/${SAMPLE}.sorted.bam"
fi

echo "▶ Stats"
samtools flagstat "$OUTDIR/${SAMPLE}.sorted.bam" > "$OUTDIR/${SAMPLE}.flagstat.txt"
samtools stats    "$OUTDIR/${SAMPLE}.sorted.bam" > "$OUTDIR/${SAMPLE}.stats.txt"

date
echo "✅ DONE ($SAMPLE)"
