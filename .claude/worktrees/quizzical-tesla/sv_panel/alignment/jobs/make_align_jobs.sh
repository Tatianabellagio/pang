#!/usr/bin/env bash
set -euo pipefail

BASE=/home/tbellagio/scratch/pang/sv_panel
IN_DIR="$BASE/assemblies_clean"
TEMPLATE="$BASE/alignment/jobs/align_asm_to_tair10.sh"
OUT_DIR="$BASE/alignment/jobs/scripts"
LOG_DIR="$BASE/alignment/jobs/logs"

mkdir -p "$OUT_DIR" "$LOG_DIR"

shopt -s nullglob
FASTAS=("$IN_DIR"/*.fa "$IN_DIR"/*.fasta "$IN_DIR"/*.fa.gz "$IN_DIR"/*.fasta.gz)
shopt -u nullglob

if [[ ${#FASTAS[@]} -eq 0 ]]; then
  echo "No FASTA files found in $IN_DIR" >&2
  exit 1
fi

echo "Found ${#FASTAS[@]} assemblies in $IN_DIR"

for asm in "${FASTAS[@]}"; do
  asm_base=$(basename "$asm")
  asm_name=${asm_base%.gz}
  asm_name=${asm_name%.fasta}
  asm_name=${asm_name%.fa}

  out="$OUT_DIR/aln_${asm_name}.sh"

  sed \
    -e "s/aln_ASMNAME/aln_${asm_name}/g" \
    -e "s|^ASM=.*|ASM=${asm}|g" \
    "$TEMPLATE" > "$out"

  chmod +x "$out"
done

echo "Wrote job scripts to: $OUT_DIR"
echo "Example:"
echo "  sbatch $OUT_DIR/aln_${asm_name}.sh"
