#!/bin/bash -l
#SBATCH --job-name=FREQK_S1
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --export=ALL
#SBATCH --output=FREQK_S1.%j.out
#SBATCH --error=FREQK_S1.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"

# Keep env clean (same pattern you use)
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate freqk_build

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
READSDIR=/home/tbellagio/scratch/pang/grenenet_reads/seed_mix
WORK=/home/tbellagio/scratch/pang/test_freqk/run_set_02_rep1_S1

cd "$WORK"

S=S1
K=31
INDEX=set_02_rep1.k${K}.freqk.index

R1=${READSDIR}/${S}-1.1_P.fq.gz
R2=${READSDIR}/${S}-1.2_P.fq.gz
READS="${R1},${R2}"

COUNTS_BY_ALLELE=${S}.counts_by_allele.k${K}.tsv
RAW_COUNTS=${S}.raw_kmer_counts.k${K}.tsv
AF_OUT=${S}.allele_frequencies.k${K}.tsv

# guards
[[ -s "$INDEX" ]] || { echo "Missing index: $WORK/$INDEX" >&2; exit 1; }
[[ -s "$R1" ]] || { echo "Missing reads: $R1" >&2; exit 1; }
[[ -s "$R2" ]] || { echo "Missing reads: $R2" >&2; exit 1; }

echo "Sample: $S"
echo "Index:  $WORK/$INDEX"
echo "Reads:  $READS"
echo "Threads: $SLURM_CPUS_PER_TASK"

# Count
$FREQK count \
  --index "$INDEX" \
  --reads "$READS" \
  --nthreads "$SLURM_CPUS_PER_TASK" \
  --freq-output "$COUNTS_BY_ALLELE" \
  --count-output "$RAW_COUNTS"

# Call
$FREQK call \
  --index "$INDEX" \
  --counts "$COUNTS_BY_ALLELE" \
  --output "$AF_OUT"

echo "✅ Done $S"
ls -lh "$COUNTS_BY_ALLELE" "$RAW_COUNTS" "$AF_OUT"
head -n 5 "$AF_OUT" || true
