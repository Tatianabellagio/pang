#!/bin/bash
#SBATCH --job-name=aln_ASMNAME
#SBATCH --output=logs/aln_ASMNAME.%j.out
#SBATCH --error=logs/aln_ASMNAME.%j.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
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

conda activate pang
START_TS=$(date +%s)
echo "▶ START: $(date)"

# ---- inputs (edit these per job or pass via env vars) ----
REF=/home/tbellagio/scratch/pang/sv_panel/ref/TAIR10.Chr.fa
ASM=/home/tbellagio/scratch/pang/sv_panel/assemblies_clean/Abd-0.fasta

# ---- outputs ----
OUTROOT=/home/tbellagio/scratch/pang/sv_panel/alignment
ASMNAME=$(basename "$ASM")
ASMNAME=${ASMNAME%.gz}
ASMNAME=${ASMNAME%.fasta}
ASMNAME=${ASMNAME%.fa}

BAMDIR="$OUTROOT/alignments/$ASMNAME"
mkdir -p "$BAMDIR" "$OUTROOT/logs"

THREADS=${SLURM_CPUS_PER_TASK:-16}
BAM="$BAMDIR/${ASMNAME}.tair10.bam"

# ---- handle gz assemblies safely ----
if [[ "$ASM" == *.gz ]]; then
  # stream to minimap2
  ASM_STREAM="<(gzip -dc "$ASM")"
else
  ASM_STREAM="$ASM"
fi

# ---- align + sort + index ----
minimap2 -ax asm5 --eqx -t "$THREADS" "$REF" "$ASM_STREAM" \
  | samtools sort -@ "$THREADS" -O BAM -o "$BAM" -

END_TS=$(date +%s)
echo "✅ END:   $(date)"
echo "⏱ TOTAL: $((END_TS - START_TS)) seconds"

echo "DONE: $BAM"
