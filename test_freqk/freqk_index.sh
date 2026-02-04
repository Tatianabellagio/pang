#!/bin/bash -l
#SBATCH --job-name=FREQK_INDEX
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --export=ALL
#SBATCH --output=FREQK_INDEX.%j.out
#SBATCH --error=FREQK_INDEX.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate freqk_build

FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk
FASTA=/home/tbellagio/scratch/pang/ref_gen/TAIR10.nuclear.Chr.fa
WORK=/home/tbellagio/scratch/pang/test_freqk/run_set_02_rep1_S1
VCF=$WORK/set_02_rep1.deconstruct.top.renamed.vcf.gz

cd "$WORK"

K=31
OUT=set_02_rep1.k${K}.freqk.index

$FREQK index --fasta "$FASTA" --vcf "$VCF" --output "$OUT" --kmer "$K"

echo "✅ Index built: $WORK/$OUT"
ls -lh "$OUT"
