#!/bin/bash
set -euo pipefail

# =========================
# Arguments
# =========================
SET_NAME=$1        # e.g. set_02_rep1
SAMPLE=$2          # e.g. S1
THREADS=${3:-16}   # optional, default 16

# =========================
# Paths (centralized)
# =========================
BASE=~/scratch/pang/pang_experiment_ref
READ_DIR=~/scratch/pang/grenenet_reads/seed_mix

PANG_DIR=$BASE/pangenomes/$SET_NAME
GBZ=$PANG_DIR/output/${SET_NAME}.d2.gbz  # keep if that's what you have

OUTDIR=$PANG_DIR/mapping/seedmix/$SAMPLE
R1=$READ_DIR/${SAMPLE}-1.1_P.fq.gz
R2=$READ_DIR/${SAMPLE}-1.2_P.fq.gz

# =========================
# Helpers
# =========================
timestamp() { date -Iseconds; }

# =========================
# Sanity checks
# =========================
echo "▶ Mapping sample $SAMPLE to $SET_NAME"
[[ -f "$GBZ" ]] || { echo "❌ Missing GBZ: $GBZ"; exit 1; }
[[ -f "$R1"  ]] || { echo "❌ Missing R1: $R1"; exit 1; }
[[ -f "$R2"  ]] || { echo "❌ Missing R2: $R2"; exit 1; }

mkdir -p "$OUTDIR"

# =========================
# 1. Graph mapping
# =========================
echo "▶ START $(timestamp)"
start_ts=$(date +%s)

echo "▶ Running vg giraffe"
vg giraffe \
  -Z "$GBZ" \
  -f "$R1" \
  -f "$R2" \
  -o GAM \
  -t "$THREADS" \
  > "$OUTDIR/${SAMPLE}.gam"

end_ts=$(date +%s)
echo "▶ END $(timestamp)"
echo "▶ RUNTIME_SECONDS $((end_ts - start_ts))"

# =========================
# 2. Mapping statistics
# =========================
echo "▶ Computing vg stats"
vg stats -a "$OUTDIR/${SAMPLE}.gam" > "$OUTDIR/${SAMPLE}.stats.txt"

# =========================
# 3. TSV alignment fields
# =========================
echo "▶ Exporting alignment TSV (name, identity, is_perfect, mapping_quality, length)"
vg filter \
  --tsv-out "name;identity;is_perfect;mapping_quality;length" \
  "$OUTDIR/${SAMPLE}.gam" \
  > "$OUTDIR/${SAMPLE}.alignment_stats.tsv"

echo "✅ DONE: $SET_NAME / $SAMPLE"
