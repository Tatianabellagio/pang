#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIG
# =========================
SVPANEL="/home/tbellagio/scratch/pang/sv_panel"
IN_DIR="/home/tbellagio/scratch/pang/pang_69/upload_genome"

OUT_DIR="${SVPANEL}/assemblies_clean"
LOG_DIR="${SVPANEL}/logs"
mkdir -p "$OUT_DIR" "$LOG_DIR"

LOG="${LOG_DIR}/clean_assemblies_keepname_chr1-5.$(date +%Y%m%d_%H%M%S).log"

# Keep only nuclear chromosomes
KEEP_CONTIGS=(Chr1 Chr2 Chr3 Chr4 Chr5)

PATTERNS=(
  "*.fa" "*.fasta" "*.fna"
  "*.fa.gz" "*.fasta.gz" "*.fna.gz"
)

# =========================
# HELPERS
# =========================
# output file keeps original filename (minus .gz if present)
out_path_for() {
  local in="$1"
  local bn
  bn="$(basename "$in")"
  bn="${bn%.gz}"   # keep original extension, just drop gzip suffix
  echo "${OUT_DIR}/${bn}"
}

# count fasta records
count_records() {
  local fa="$1"
  grep -c '^>' "$fa" 2>/dev/null || echo 0
}

# check that output already looks complete
already_done() {
  local out="$1"
  [[ -s "$out" ]] || return 1
  [[ -s "${out}.fai" ]] || return 1
  [[ "$(count_records "$out")" -eq 5 ]] || return 1
  # ensure it has the right headers at least once
  for c in Chr1 Chr2 Chr3 Chr4 Chr5; do
    grep -q "^>${c}\b" "$out" || return 1
  done
  return 0
}

# samtools faidx contig existence check
has_contig() {
  local fa="$1" contig="$2"
  samtools faidx "$fa" "$contig" >/dev/null 2>&1
}

# =========================
# MAIN
# =========================
{
  echo "[$(date)] Starting assembly cleaning (keep original filenames)"
  echo "IN_DIR:  $IN_DIR"
  echo "OUT_DIR: $OUT_DIR"
  echo "KEEP:    ${KEEP_CONTIGS[*]}"
  echo
} | tee -a "$LOG"

shopt -s nullglob

inputs=()
for p in "${PATTERNS[@]}"; do
  for f in "$IN_DIR"/$p; do
    [[ -e "$f" ]] || continue
    inputs+=("$f")
  done
done

if [[ ${#inputs[@]} -eq 0 ]]; then
  echo "[$(date)] ERROR: No assemblies found in $IN_DIR" | tee -a "$LOG" >&2
  exit 1
fi

echo "[$(date)] Found ${#inputs[@]} assemblies" | tee -a "$LOG"
echo | tee -a "$LOG"

for ASM in "${inputs[@]}"; do
  OUT="$(out_path_for "$ASM")"

  echo "----" | tee -a "$LOG"
  echo "[$(date)] Processing: $ASM" | tee -a "$LOG"
  echo "[$(date)] Output:     $OUT" | tee -a "$LOG"

  if already_done "$OUT"; then
    echo "[$(date)]  - already done, skipping" | tee -a "$LOG"
    continue
  fi

  TMP_ASM=""
  ASM_FOR_FAIDX="$ASM"

  # if gz, unzip to a temp file (in OUT_DIR so it’s on the same filesystem)
  if [[ "$ASM" == *.gz ]]; then
    TMP_ASM="${OUT_DIR}/.$(basename "${OUT}").tmp_unzipped.fa"
    echo "[$(date)]  - gz detected: writing temp uncompressed copy: $TMP_ASM" | tee -a "$LOG"
    gzip -dc "$ASM" > "$TMP_ASM"
    ASM_FOR_FAIDX="$TMP_ASM"
  fi

  # index input if needed
  if [[ ! -f "${ASM_FOR_FAIDX}.fai" ]]; then
    echo "[$(date)]  - indexing input fasta with samtools faidx" | tee -a "$LOG"
    samtools faidx "$ASM_FOR_FAIDX"
  fi

  # ensure required contigs exist
  missing=()
  for c in "${KEEP_CONTIGS[@]}"; do
    if ! has_contig "$ASM_FOR_FAIDX" "$c"; then
      missing+=("$c")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "[$(date)]  !! SKIP (missing contigs): ${missing[*]}" | tee -a "$LOG"
    [[ -n "$TMP_ASM" ]] && rm -f "$TMP_ASM" "${TMP_ASM}.fai" 2>/dev/null || true
    continue
  fi

  # write to a temp output first, then atomically move in place
  OUT_TMP="${OUT}.tmp"
  echo "[$(date)]  - extracting: ${KEEP_CONTIGS[*]} -> $OUT" | tee -a "$LOG"
  samtools faidx "$ASM_FOR_FAIDX" "${KEEP_CONTIGS[@]}" > "$OUT_TMP"
  samtools faidx "$OUT_TMP"

  mv -f "$OUT_TMP" "$OUT"
  mv -f "${OUT_TMP}.fai" "${OUT}.fai"

  nrec=$(count_records "$OUT")
  echo "[$(date)]  - wrote $OUT ($nrec records)" | tee -a "$LOG"

  # cleanup temp input if used
  if [[ -n "$TMP_ASM" ]]; then
    rm -f "$TMP_ASM" "${TMP_ASM}.fai" 2>/dev/null || true
  fi
done

echo | tee -a "$LOG"
echo "[$(date)] DONE. Log: $LOG" | tee -a "$LOG"
