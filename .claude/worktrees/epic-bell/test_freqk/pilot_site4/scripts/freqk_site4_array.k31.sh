#!/bin/bash -l
#SBATCH --job-name=FREQK_SITE4
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --time=12:00:00
#SBATCH --array=0-999%10
#SBATCH --output=logs/FREQK_SITE4.%A_%a.out
#SBATCH --error=logs/FREQK_SITE4.%A_%a.err
#SBATCH --export=ALL

set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate freqk_build

ts() { date +"%Y-%m-%d %H:%M:%S %Z"; }

BASE=/home/tbellagio/scratch/pang/test_freqk/pilot_site4
FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
VCF=${BASE}/set_05_rep1.vcf.gz
FASTA=/home/tbellagio/scratch/pang/ref_gen/TAIR10.nuclear.Chr.fa
K=31
INDEX=${BASE}/set_05_rep1.TAIR10.k${K}.freqk.index

mkdir -p "${BASE}/logs" "${BASE}/results"

echo "===== START $(ts) ====="
echo "HOST=$(hostname)"
echo "PWD=$(pwd)"
echo "BASE=$BASE"
echo "TASK=${SLURM_ARRAY_TASK_ID}"
echo "CPUs=${SLURM_CPUS_PER_TASK:-8}"
echo

# ---- Build list of available trimmed R1s (paired reads) ----
# Expect: trimmed/site4_000.R1.P.fq.gz etc.
mapfile -t R1S < <(ls -1 ${BASE}/trimmed/site4_*.R1.P.fq.gz 2>/dev/null | sort)
N=${#R1S[@]}

if (( N == 0 )); then
  echo "ERROR: No trimmed R1 files found under ${BASE}/trimmed" >&2
  ls -lh "${BASE}/trimmed" || true
  exit 1
fi

if (( SLURM_ARRAY_TASK_ID >= N )); then
  echo "Task ${SLURM_ARRAY_TASK_ID} >= N=${N}, nothing to do."
  exit 0
fi

R1="${R1S[$SLURM_ARRAY_TASK_ID]}"
R2="${R1/.R1.P.fq.gz/.R2.P.fq.gz}"

ID=$(basename "$R1" .R1.P.fq.gz)   # e.g. site4_000
READS="${R1},${R2}"

WORK="${BASE}/results/${ID}/k${K}"
mkdir -p "$WORK"
cd "$WORK"

VAR_INDEX="${ID}.k${K}.freqk.var_index"
REF_INDEX="${ID}.k${K}.freqk.ref_index"
COUNTS_BY_ALLELE="${ID}.counts_by_allele.k${K}.dedup.tsv"
RAW_COUNTS="${ID}.raw_kmer_counts.k${K}.dedup.tsv"
AF_OUT="${ID}.allele_frequencies.k${K}.dedup.tsv"

echo "ID=$ID"
echo "R1=$R1"
echo "R2=$R2"
echo "READS=$READS"
echo "WORK=$WORK"
echo

# ---- Guards ----
[[ -s "$FREQK" ]] || { echo "Missing freqk binary: $FREQK" >&2; exit 1; }
[[ -s "$INDEX" ]] || { echo "Missing index: $INDEX" >&2; exit 1; }
[[ -s "$VCF" && -s "${VCF}.tbi" ]] || { echo "Missing VCF or tbi: $VCF" >&2; exit 1; }
[[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai: $FASTA" >&2; exit 1; }
[[ -s "$R1" ]] || { echo "Missing trimmed R1: $R1" >&2; exit 1; }
[[ -s "$R2" ]] || { echo "Missing trimmed R2: $R2" >&2; exit 1; }

# ---- Run ----
echo "===== var-dedup $(ts) ====="
"$FREQK" var-dedup --index "$INDEX" --output "$VAR_INDEX"

echo "===== ref-dedup $(ts) ====="
"$FREQK" ref-dedup -i "$VAR_INDEX" -o "$REF_INDEX" -f "$FASTA" --vcf "$VCF"

echo "===== count $(ts) ====="
"$FREQK" count \
  --index "$REF_INDEX" \
  --reads "$READS" \
  --nthreads "${SLURM_CPUS_PER_TASK:-8}" \
  --freq-output "$COUNTS_BY_ALLELE" \
  --count-output "$RAW_COUNTS"

echo "===== call $(ts) ====="
"$FREQK" call \
  --index "$REF_INDEX" \
  --counts "$COUNTS_BY_ALLELE" \
  --output "$AF_OUT"

echo
echo "✅ Done: $AF_OUT"
ls -lh "$AF_OUT" || true
echo "===== END $(ts) ====="
