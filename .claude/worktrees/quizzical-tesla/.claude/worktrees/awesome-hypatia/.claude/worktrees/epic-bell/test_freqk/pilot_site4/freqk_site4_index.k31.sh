#!/bin/bash -l
#SBATCH --job-name=FREQK_INDEX_S4
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=logs/FREQK_INDEX_S4.%j.out
#SBATCH --error=logs/FREQK_INDEX_S4.%j.err
#SBATCH --export=ALL

set -euo pipefail
eval "$(conda shell.bash hook)"
conda activate freqk_build

BASE=/home/tbellagio/scratch/pang/test_freqk/pilot_site4
cd "$BASE"
mkdir -p logs

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
VCF=$BASE/set_05_rep1.vcf.gz
FASTA=/home/tbellagio/scratch/pang/ref_gen/TAIR10.nuclear.Chr.fa
K=31
OUT=$BASE/set_05_rep1.TAIR10.k${K}.freqk.index

[[ -s "$FREQK" ]] || { echo "Missing freqk binary: $FREQK" >&2; exit 1; }
[[ -s "$VCF" && -s "${VCF}.tbi" ]] || { echo "Missing VCF or tbi: $VCF" >&2; exit 1; }
[[ -s "$FASTA" && -s "${FASTA}.fai" ]] || { echo "Missing FASTA or fai: $FASTA" >&2; exit 1; }

"$FREQK" index --fasta "$FASTA" --vcf "$VCF" --output "$OUT" --kmer "$K"

echo "✅ Index built:"
ls -lh "$OUT"
