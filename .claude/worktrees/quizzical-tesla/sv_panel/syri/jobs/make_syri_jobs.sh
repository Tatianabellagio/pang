#!/usr/bin/env bash
set -euo pipefail

BASE=/home/tbellagio/scratch/pang/sv_panel
ASM_DIR="$BASE/assemblies_clean"
ALN_DIR="$BASE/alignment/alignments"
TEMPLATE="$BASE/syri/jobs/syri_from_bam.sh"
OUT_DIR="$BASE/syri/jobs/scripts"
LOG_DIR="$BASE/syri/logs"

mkdir -p "$OUT_DIR" "$LOG_DIR"

shopt -s nullglob
ASMS=("$ASM_DIR"/*.fa "$ASM_DIR"/*.fasta "$ASM_DIR"/*.fa.gz "$ASM_DIR"/*.fasta.gz)
shopt -u nullglob

if [[ ${#ASMS[@]} -eq 0 ]]; then
  echo "No assemblies found in $ASM_DIR" >&2
  exit 1
fi

echo "Found ${#ASMS[@]} assemblies in $ASM_DIR"

n_ok=0
n_skip=0

for asm in "${ASMS[@]}"; do
  base=$(basename "$asm")
  name=${base%.gz}
  name=${name%.fasta}
  name=${name%.fa}

  bam="$ALN_DIR/$name/${name}.tair10.bam"
  if [[ ! -s "$bam" ]]; then
    echo "SKIP (no BAM): $name -> expected $bam"
    ((n_skip+=1))
    continue
  fi

  out="$OUT_DIR/syri_${name}.sh"

  sed \
    -e "s/syri_ASMNAME/syri_${name}/g" \
    -e "s|^ASM=.*|ASM=${asm}|g" \
    -e "s|^BAM=.*|BAM=${bam}|g" \
    "$TEMPLATE" > "$out"

  chmod +x "$out"
  ((n_ok+=1))
done

echo
echo "Wrote $n_ok SyRI job scripts to: $OUT_DIR"
echo "Skipped $n_skip (missing BAMs)"
