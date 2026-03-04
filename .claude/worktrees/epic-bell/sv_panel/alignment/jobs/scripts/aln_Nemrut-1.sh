#!/bin/bash
#SBATCH --job-name=aln_Nemrut-1
#SBATCH --output=logs/aln_Nemrut-1.%j.out
#SBATCH --error=logs/aln_Nemrut-1.%j.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G

set -euo pipefail

eval "$(conda shell.bash hook)"
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate pang

START_TS=$(date +%s)
echo "▶ START: $(date)"

REF=/home/tbellagio/scratch/pang/sv_panel/ref/TAIR10.Chr.fa
ASM=/home/tbellagio/scratch/pang/sv_panel/assemblies_clean/Nemrut-1.fasta

OUTROOT=/home/tbellagio/scratch/pang/sv_panel/alignment

ASMNAME=$(basename "$ASM")
ASMNAME=${ASMNAME%.gz}
ASMNAME=${ASMNAME%.fasta}
ASMNAME=${ASMNAME%.fa}

BAMDIR="$OUTROOT/alignments/$ASMNAME"
mkdir -p "$BAMDIR" "$OUTROOT/jobs/logs"

THREADS=${SLURM_CPUS_PER_TASK:-16}
BAM="$BAMDIR/${ASMNAME}.tair10.bam"

# if you ever have gz again, unpack once to $BAMDIR
if [[ "$ASM" == *.gz ]]; then
  ASM_UNZ="$BAMDIR/${ASMNAME}.fa"
  [[ -s "$ASM_UNZ" ]] || gzip -dc "$ASM" > "$ASM_UNZ"
  ASM_FOR_ALIGN="$ASM_UNZ"
else
  ASM_FOR_ALIGN="$ASM"
fi

minimap2 -ax asm5 --eqx -t "$THREADS" "$REF" "$ASM_FOR_ALIGN" \
  | samtools sort -@ "$THREADS" -O BAM -o "$BAM" -

samtools index -@ "$THREADS" "$BAM"

END_TS=$(date +%s)
echo "✅ END:   $(date)"
echo "⏱ TOTAL: $((END_TS - START_TS)) seconds"
echo "DONE: $BAM"
