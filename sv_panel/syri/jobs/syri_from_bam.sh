#!/bin/bash
#SBATCH --job-name=syri_ASMNAME
#SBATCH --output=/home/tbellagio/scratch/pang/sv_panel/syri/logs/syri_ASMNAME.%j.out
#SBATCH --error=/home/tbellagio/scratch/pang/sv_panel/syri/logs/syri_ASMNAME.%j.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G

set -euo pipefail

# =========================
# Load environment
# =========================
eval "$(conda shell.bash hook)"

# 🔑 FIX: ensure PYTHONPATH is defined (prevents cactus env crash)
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate syri_env

# -----------------------------
# Inputs (edit per job)
# -----------------------------
REF=/home/tbellagio/scratch/pang/sv_panel/ref/TAIR10.Chr.fa
ASM=/home/tbellagio/scratch/pang/pang_69/upload_genome/Abd-0.fasta

# This should match where your align job wrote it:
BAM=/home/tbellagio/scratch/pang/sv_panel/alignment/alignments/Abd-0/Abd-0.tair10.bam

# -----------------------------
# Output layout
# -----------------------------
OUTROOT=/home/tbellagio/scratch/pang/sv_panel/syri
mkdir -p "$OUTROOT/results" "$OUTROOT/logs"

ASMNAME=$(basename "$ASM")
ASMNAME=${ASMNAME%.gz}
ASMNAME=${ASMNAME%.fasta}
ASMNAME=${ASMNAME%.fa}

SYRIDIR="$OUTROOT/results/$ASMNAME"
mkdir -p "$SYRIDIR"

THREADS=${SLURM_CPUS_PER_TASK:-8}

# -----------------------------
# Ensure inputs exist
# -----------------------------
[[ -s "$REF" ]] || { echo "Missing REF: $REF" >&2; exit 1; }
[[ -s "$ASM" ]] || { echo "Missing ASM: $ASM" >&2; exit 1; }
[[ -s "$BAM" ]] || { echo "Missing BAM: $BAM" >&2; exit 1; }
[[ -s "${BAM}.bai" ]] || { echo "Missing BAM index: ${BAM}.bai" >&2; exit 1; }

# -----------------------------
# Syri: query FASTA must be readable
# If gz, unpack once into SYRIDIR
# -----------------------------
if [[ "$ASM" == *.gz ]]; then
  ASM_FOR_SYRI="$SYRIDIR/${ASMNAME}.fa"
  if [[ ! -s "$ASM_FOR_SYRI" ]]; then
    gzip -dc "$ASM" > "$ASM_FOR_SYRI"
  fi
else
  ASM_FOR_SYRI="$ASM"
fi

# -----------------------------
# Run syri (BAM input)
# -----------------------------
syri -c "$BAM" \
     -r "$REF" \
     -q "$ASM_FOR_SYRI" \
     -F B \
     --dir "$SYRIDIR" \
     --prefix "${ASMNAME}.tair10." \
     --nc "$THREADS"

echo "DONE: $SYRIDIR"
