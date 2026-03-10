#!/bin/bash
#SBATCH --job-name=syri_Can-0
#SBATCH --output=/home/tbellagio/scratch/pang/sv_panel/syri/logs/syri_Can-0.%j.out
#SBATCH --error=/home/tbellagio/scratch/pang/sv_panel/syri/logs/syri_Can-0.%j.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G

set -euo pipefail

eval "$(conda shell.bash hook)"
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate syri_env

START_TS=$(date +%s)
echo "▶ START: $(date)"

REF=/home/tbellagio/scratch/pang/sv_panel/ref/TAIR10.Chr.fa
ASM=/home/tbellagio/scratch/pang/sv_panel/assemblies_clean/Can-0.fasta
BAM=/home/tbellagio/scratch/pang/sv_panel/alignment/alignments/Can-0/Can-0.tair10.bam

OUTROOT=/home/tbellagio/scratch/pang/sv_panel/syri
mkdir -p "$OUTROOT/results" "$OUTROOT/logs"

ASMNAME=$(basename "$ASM")
ASMNAME=${ASMNAME%.gz}
ASMNAME=${ASMNAME%.fasta}
ASMNAME=${ASMNAME%.fa}

SYRIDIR="$OUTROOT/results/$ASMNAME"
mkdir -p "$SYRIDIR"

THREADS=${SLURM_CPUS_PER_TASK:-8}

[[ -s "$REF" ]] || { echo "Missing REF: $REF" >&2; exit 1; }
[[ -s "$ASM" ]] || { echo "Missing ASM: $ASM" >&2; exit 1; }
[[ -s "$BAM" ]] || { echo "Missing BAM: $BAM" >&2; exit 1; }

# Ensure BAM index exists (create if missing)
if [[ ! -s "${BAM}.bai" ]]; then
  echo "⚠ Missing BAM index; creating: ${BAM}.bai"
  samtools index -@ "$THREADS" "$BAM"
fi

if [[ "$ASM" == *.gz ]]; then
  ASM_FOR_SYRI="$SYRIDIR/${ASMNAME}.fa"
  if [[ ! -s "$ASM_FOR_SYRI" ]]; then
    gzip -dc "$ASM" > "$ASM_FOR_SYRI"
  fi
else
  ASM_FOR_SYRI="$ASM"
fi

syri -c "$BAM" \
     -r "$REF" \
     -q "$ASM_FOR_SYRI" \
     -F B \
     --dir "$SYRIDIR" \
     --prefix "${ASMNAME}.tair10." \
     --nc "$THREADS"

END_TS=$(date +%s)
echo "✅ END:   $(date)"
echo "⏱ TOTAL: $((END_TS - START_TS)) seconds"
echo "DONE: $SYRIDIR"
