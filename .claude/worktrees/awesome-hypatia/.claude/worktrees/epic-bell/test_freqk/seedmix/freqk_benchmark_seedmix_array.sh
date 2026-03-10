#!/bin/bash -l
#SBATCH --job-name=FREQK_SM
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --time=12:00:00
#SBATCH --export=ALL
#SBATCH --array=0-7
#SBATCH --output=logs/FREQK_SM.%A_%a.out
#SBATCH --error=logs/FREQK_SM.%A_%a.err

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

eval "$(conda shell.bash hook)"
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate freqk_build

BASE=/home/tbellagio/scratch/pang/test_freqk/seedmix
mkdir -p "$BASE/logs" "$BASE/results"
cd "$BASE"

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
VCF=$BASE/greneNet_final_v1.1.recode.vcf.gz
FASTA=/home/tbellagio/scratch/pang/ref_xing/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa
#/home/tbellagio/scratch/pang/ref_gen/TAIR10.nuclear.Chr.fa

K=21
INDEX=$BASE/greneNet_v1.1.TAIR10.k${K}.freqk.index

READSDIR=/home/tbellagio/scratch/pang/grenenet_reads/seed_mix

SAMPLES=(S1 S2 S3 S4 S5 S6 S7 S8)
S="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"

# update these if your naming differs
R1=${READSDIR}/${S}-1.1_P.fq.gz
R2=${READSDIR}/${S}-1.2_P.fq.gz
READS="${R1},${R2}"

# per-sample workdir (keeps dedup outputs separate)
WORK=$BASE/results/${S}/k${K}
mkdir -p "$WORK"
cd "$WORK"

VAR_INDEX=${S}.k${K}.freqk.var_index
REF_INDEX=${S}.k${K}.freqk.ref_index

COUNTS_BY_ALLELE=${S}.counts_by_allele.k${K}.dedup.tsv
RAW_COUNTS=${S}.raw_kmer_counts.k${K}.dedup.tsv
AF_OUT=${S}.allele_frequencies.k${K}.dedup.tsv

echo "Job started: $(ts)"
echo "Node: $(hostname)"
echo "Sample: $S"
echo "CWD:    $(pwd)"
echo "CPUs:   ${SLURM_CPUS_PER_TASK:-NA}"
echo "Reads:  $READS"
echo

# guards
[[ -s "$FREQK" ]] || { echo "Missing freqk binary: $FREQK" >&2; exit 1; }
[[ -s "$INDEX" ]] || { echo "Missing index: $INDEX" >&2; exit 1; }
[[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai: $FASTA" >&2; exit 1; }
[[ -s "$VCF" && -s "${VCF}.tbi" ]] || { echo "Missing VCF or tbi: $VCF" >&2; exit 1; }
[[ -s "$R1" ]] || { echo "Missing R1: $R1" >&2; exit 1; }
[[ -s "$R2" ]] || { echo "Missing R2: $R2" >&2; exit 1; }

step "var-dedup" \
  "$FREQK" var-dedup --index "$INDEX" --output "$VAR_INDEX"

step "ref-dedup" \
  "$FREQK" ref-dedup -i "$VAR_INDEX" -o "$REF_INDEX" -f "$FASTA" --vcf "$VCF"

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
