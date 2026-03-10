#!/bin/bash -l
#SBATCH --job-name=freqk_dcc_all
#SBATCH --output=logs/07_freqk_dcc_all_%j.out
#SBATCH --error=logs/07_freqk_dcc_all_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=08:00:00
# =============================================================================
# 07_freqk_dedup_count_call_all_noerror.sh
# Purpose: var-dedup, ref-dedup, count, call for freq=0.50 pools, all sizes, no error
# =============================================================================
set -euo pipefail
eval "$(conda shell.bash hook)"
conda activate freqk_build

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
WORK=/home/tbellagio/scratch/pang/visor_freqk
FASTA=${WORK}/data/reference/Chr1.fa
VCF_DIR=${WORK}/data/vcf
K=31

SIZES=("100bp" "500bp" "1kb" "5kb" "10kb")

for SIZE in "${SIZES[@]}"; do
  INDEX=${WORK}/results/del_${SIZE}.k${K}.freqk.index
  VAR_INDEX=${WORK}/results/del_${SIZE}.k${K}.freqk.var_index
  REF_INDEX=${WORK}/results/del_${SIZE}.k${K}.freqk.ref_index

  READS_DIR=${WORK}/data/reads/freq_${SIZE}_050_noerr
  RESULTS_DIR=${WORK}/results/${SIZE}_noerr
  mkdir -p "${RESULTS_DIR}"

  READS_COMBINED=${READS_DIR}/all.fq
  COUNTS_BY_ALLELE=${RESULTS_DIR}/freq_${SIZE}_050_noerr.counts_by_allele.k${K}.tsv
  RAW_COUNTS=${RESULTS_DIR}/freq_${SIZE}_050_noerr.raw_kmer_counts.k${K}.tsv
  AF_OUT=${RESULTS_DIR}/freq_${SIZE}_050_noerr.allele_frequencies.k${K}.tsv

  VCF=${VCF_DIR}/del_${SIZE}.vcf.gz

  echo
  echo "==== Size ${SIZE} ===="

  [[ -s "$INDEX"          ]] || { echo "Missing index: $INDEX" >&2; continue; }
  [[ -s "$FASTA"          ]] || { echo "Missing FASTA" >&2; exit 1; }
  [[ -s "$VCF"            ]] || { echo "Missing VCF: $VCF"   >&2; continue; }
  [[ -s "$READS_DIR/r1.fq" && -s "$READS_DIR/r2.fq" ]] || { echo "Missing reads for ${SIZE}" >&2; continue; }

  echo "[$(date)] Combining r1.fq + r2.fq -> all.fq (${SIZE})"
  cat ${READS_DIR}/r1.fq ${READS_DIR}/r2.fq > "$READS_COMBINED"

  step() {
    local label="$1"; shift
    echo
    echo "[$(date)] === $label (${SIZE}) ==="
    echo "+ $*"
    "$@"
  }

  step "var-dedup" \
    "$FREQK" var-dedup --index "$INDEX" --output "$VAR_INDEX"
  ls -lh "$VAR_INDEX"

  step "ref-dedup" \
    "$FREQK" ref-dedup -i "$VAR_INDEX" -o "$REF_INDEX" -f "$FASTA" --vcf "$VCF"
  ls -lh "$REF_INDEX"

  step "count" \
    "$FREQK" count \
      --index "$REF_INDEX" \
      --reads "$READS_COMBINED" \
      --nthreads "${SLURM_CPUS_PER_TASK}" \
      --freq-output "$COUNTS_BY_ALLELE" \
      --count-output "$RAW_COUNTS"

  step "call" \
    "$FREQK" call \
      --index "$REF_INDEX" \
      --counts "$COUNTS_BY_ALLELE" \
      --output "$AF_OUT"

  echo "[$(date)] Done for ${SIZE}. AF:"
  cat "$AF_OUT"
done