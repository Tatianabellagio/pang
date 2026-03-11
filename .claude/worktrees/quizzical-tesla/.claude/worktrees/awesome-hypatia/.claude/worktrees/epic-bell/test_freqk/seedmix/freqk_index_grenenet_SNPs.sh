#!/bin/bash -l
#SBATCH --job-name=FREQK_INDEX_SM
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --export=ALL
#SBATCH --output=logs/FREQK_INDEX_SM.%j.out
#SBATCH --error=logs/FREQK_INDEX_SM.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate freqk_build

ts() { date +"%Y-%m-%d %H:%M:%S %Z"; }
step() {
  local name="$1"; shift
  echo; echo "===== [$name] START $(ts) ====="
  local start=$SECONDS
  "$@"
  local dur=$((SECONDS - start))
  echo "===== [$name] END   $(ts) | duration=${dur}s ====="
}

BASE=/home/tbellagio/scratch/pang/test_freqk/seedmix
mkdir -p "$BASE/logs"
cd "$BASE"

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk

VCF=$BASE/greneNet_final_v1.1.recode.vcf.gz
FASTA=/home/tbellagio/scratch/pang/ref_xing/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa
#/home/tbellagio/scratch/pang/ref_gen/TAIR10.nuclear.Chr.fa

K=21
OUT=$BASE/greneNet_v1.1.TAIR10.k${K}.freqk.index

# guards
[[ -s "$FREQK" ]] || { echo "Missing freqk binary: $FREQK" >&2; exit 1; }
[[ -s "$VCF" && -s "${VCF}.tbi" ]] || { echo "Missing VCF or tbi: $VCF" >&2; exit 1; }
[[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai: $FASTA" >&2; exit 1; }

echo "Job started: $(ts)"
echo "Node: $(hostname)"
echo "CWD:  $(pwd)"
echo "VCF:  $VCF"
echo "FASTA:$FASTA"
echo "K:    $K"
echo

step "freqk index" \
  "$FREQK" index --fasta "$FASTA" --vcf "$VCF" --output "$OUT" --kmer "$K"

echo
echo "✅ Index built:"
ls -lh "$OUT"
echo "Job finished: $(ts)"
