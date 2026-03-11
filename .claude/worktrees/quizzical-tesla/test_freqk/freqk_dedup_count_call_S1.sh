#!/bin/bash -l
#SBATCH --job-name=FREQK_S1_DD
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --time=12:00:00
#SBATCH --export=ALL
#SBATCH --output=FREQK_S1_DD.%j.out
#SBATCH --error=FREQK_S1_DD.%j.err

set -euo pipefail

ts() { date +"%Y-%m-%d %H:%M:%S %Z"; }

step() {
  local name="$1"
  shift
  echo
  echo "===== [$name] START $(ts) ====="
  local start=$SECONDS
  "$@"
  local dur=$((SECONDS - start))
  echo "===== [$name] END   $(ts) | duration=${dur}s ====="
}

echo "Job started: $(ts)"
echo "Node: $(hostname)"
echo "CWD:  $(pwd)"
echo "CPUs: ${SLURM_CPUS_PER_TASK:-NA}"
echo

eval "$(conda shell.bash hook)"

export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate freqk_build

WORK=/home/tbellagio/scratch/pang/test_freqk/run_set_02_rep1_S1
cd "$WORK"

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
FASTA=/home/tbellagio/scratch/pang/ref_gen/TAIR10.nuclear.Chr.fa
VCF=$WORK/set_02_rep1.deconstruct.top.renamed.vcf.gz

K=31
INDEX=set_02_rep1.k${K}.freqk.index
VAR_INDEX=set_02_rep1.k${K}.freqk.var_index
REF_INDEX=set_02_rep1.k${K}.freqk.ref_index

S=S1
READSDIR=/home/tbellagio/scratch/pang/grenenet_reads/seed_mix
READS=${READSDIR}/${S}-1.1_P.fq.gz,${READSDIR}/${S}-1.2_P.fq.gz

COUNTS_BY_ALLELE=${S}.counts_by_allele.k${K}.dedup.tsv
RAW_COUNTS=${S}.raw_kmer_counts.k${K}.dedup.tsv
AF_OUT=${S}.allele_frequencies.k${K}.dedup.tsv

# guards
[[ -s "$INDEX" ]] || { echo "Missing index: $INDEX" >&2; exit 1; }
[[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai" >&2; exit 1; }
[[ -s "$VCF" && -s "${VCF}.tbi" ]] || { echo "Missing VCF or tbi" >&2; exit 1; }

step "var-dedup" \
  "$FREQK" var-dedup --index "$INDEX" --output "$VAR_INDEX"

ls -lh "$VAR_INDEX"

step "ref-dedup" \
  "$FREQK" ref-dedup -i "$VAR_INDEX" -o "$REF_INDEX" -f "$FASTA" --vcf "$VCF"

ls -lh "$REF_INDEX"

step "count" \
  "$FREQK" count \
    --index "$REF_INDEX" \
    --reads "$READS" \
    --nthreads "${SLURM_CPUS_PER_TASK}" \
    --freq-output "$COUNTS_BY_ALLELE" \
    --count-output "$RAW_COUNTS"

step "call" \
  "$FREQK" call \
    --index "$REF_INDEX" \
    --counts "$COUNTS_BY_ALLELE" \
    --output "$AF_OUT"

echo
echo "✅ Done. Outputs:"
ls -lh "$COUNTS_BY_ALLELE" "$RAW_COUNTS" "$AF_OUT"
head -n 5 "$AF_OUT" || true

echo
echo "Job finished: $(ts)"
