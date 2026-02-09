#!/bin/bash -l
#SBATCH --job-name=SITE4_TRIM
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=04:00:00
#SBATCH --array=0-75%20
#SBATCH --output=logs/SITE4_TRIM.%A_%a.out
#SBATCH --error=logs/SITE4_TRIM.%A_%a.err
#SBATCH --export=ALL

set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate pang

BASE=/home/tbellagio/scratch/pang/test_freqk/pilot_site4
cd "$BASE"
mkdir -p logs trimmed

ID=$(printf "site4_%03d" "$SLURM_ARRAY_TASK_ID")

R1="reads/${ID}.fq.gz"
R2="reads/${ID}_2.fq.gz"

OUT_R1P="trimmed/${ID}.R1.P.fq.gz"
OUT_R1U="trimmed/${ID}.R1.U.fq.gz"
OUT_R2P="trimmed/${ID}.R2.P.fq.gz"
OUT_R2U="trimmed/${ID}.R2.U.fq.gz"
LOG="trimmed/${ID}.trimmomatic.log"

ADAPTERS="${CONDA_PREFIX}/share/trimmomatic/adapters/TruSeq3-PE-2.fa"
if [[ ! -s "$ADAPTERS" ]]; then
  # fallback names some installs use
  ADAPTERS="${CONDA_PREFIX}/share/trimmomatic/adapters/TruSeq3-PE.fa"
fi

[[ -s "$R1" ]] || { echo "Missing R1: $R1" >&2; exit 1; }
[[ -s "$R2" ]] || { echo "Missing R2: $R2" >&2; exit 1; }
[[ -s "$ADAPTERS" ]] || { echo "Missing adapters fasta in conda env: tried $ADAPTERS" >&2; exit 1; }

echo "ID=$ID"
echo "R1=$R1"
echo "R2=$R2"
echo "ADAPTERS=$ADAPTERS"
echo "CPUs=${SLURM_CPUS_PER_TASK:-8}"

trimmomatic PE -phred33 -threads "${SLURM_CPUS_PER_TASK:-8}" \
  "$R1" "$R2" \
  "$OUT_R1P" "$OUT_R1U" "$OUT_R2P" "$OUT_R2U" \
  ILLUMINACLIP:"$ADAPTERS":2:30:10:8:TRUE \
  SLIDINGWINDOW:4:20 LEADING:5 TRAILING:5 MINLEN:36 \
  2>&1 | tee "$LOG"

echo "DONE $ID"
ls -lh "$OUT_R1P" "$OUT_R2P"
