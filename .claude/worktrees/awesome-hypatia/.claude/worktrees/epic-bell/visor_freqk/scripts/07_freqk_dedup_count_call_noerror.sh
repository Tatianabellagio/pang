#!/bin/bash -l
#SBATCH --job-name=freqk_dcc
#SBATCH --output=logs/07_freqk_dcc_%j.out
#SBATCH --error=logs/07_freqk_dcc_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=06:00:00
# =============================================================================
# 07_freqk_dedup_count_call.sh
# Purpose: var-dedup, ref-dedup, count, call for freq=0.50 1kb deletion pool
#          Uses error-free reads (freq_1kb_050_noerr) to test junction k-mer
#          matching without sequencing error noise
# Expected result: freqk should estimate ~0.50 allele frequency
# =============================================================================
set -euo pipefail
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

ts() { date +"%Y-%m-%d %H:%M:%S"; }
step() {
  local name="$1"; shift
  echo
  echo "===== [$name] START $(ts) ====="
  local start=$SECONDS
  "$@"
  echo "===== [$name] END $(ts) | duration=$((SECONDS - start))s ====="
}

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
WORK=/home/tbellagio/scratch/pang/visor_freqk
FASTA=${WORK}/data/reference/Chr1.fa
VCF=${WORK}/data/vcf/del_1kb.vcf.gz
K=31

INDEX=${WORK}/results/del_1kb.k${K}.freqk.index
VAR_INDEX=${WORK}/results/del_1kb.k${K}.freqk.var_index
REF_INDEX=${WORK}/results/del_1kb.k${K}.freqk.ref_index

READS_DIR=${WORK}/data/reads/freq_1kb_050_noerr
RESULTS_DIR=${WORK}/results/noerr
mkdir -p "${RESULTS_DIR}"

READS_COMBINED=${READS_DIR}/all.fq
COUNTS_BY_ALLELE=${RESULTS_DIR}/freq_1kb_050_noerr.counts_by_allele.k${K}.tsv
RAW_COUNTS=${RESULTS_DIR}/freq_1kb_050_noerr.raw_kmer_counts.k${K}.tsv
AF_OUT=${RESULTS_DIR}/freq_1kb_050_noerr.allele_frequencies.k${K}.tsv

# Combine r1 + r2 into single fastq
echo "[$(date)] Combining r1.fq + r2.fq -> all.fq"
cat ${READS_DIR}/r1.fq ${READS_DIR}/r2.fq > "$READS_COMBINED"

# Guards
[[ -s "$INDEX"          ]] || { echo "Missing index: $INDEX" >&2; exit 1; }
[[ -s "$FASTA"          ]] || { echo "Missing FASTA" >&2; exit 1; }
[[ -s "$VCF"            ]] || { echo "Missing VCF"   >&2; exit 1; }
[[ -s "$READS_COMBINED" ]] || { echo "Missing reads" >&2; exit 1; }

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

echo
echo "✅ Done. True freq=0.50, freqk estimates:"
cat "$AF_OUT"
echo
echo "[$(date)] All outputs:"
ls -lh "$COUNTS_BY_ALLELE" "$RAW_COUNTS" "$AF_OUT"