#!/bin/bash
#SBATCH --job-name=set_10_rep1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00
#SBATCH --output=set_10_rep1.%j.out
#SBATCH --error=set_10_rep1.%j.err

eval "$(conda shell.bash hook)"
conda activate pang

cd /home/tbellagio/scratch/pang/pang_experiment/pangenomes/set_10_rep1

JOBSTORE="jobstore"
OUTDIR="output"
OUTNAME="set_10_rep1"

rm -rf "$JOBSTORE"

export TMPDIR="$HOME/scratch/pang/tmp/${OUTNAME}"
mkdir -p "$TMPDIR"

cactus-pangenome \
    "$JOBSTORE" \
    seqfile.txt \
    --outDir "$OUTDIR" \
    --outName "$OUTNAME" \
    --reference TAIR10 \
    --haplo \
    --vcf \
    --gfa \
    --gbz \
    --giraffe \
    --maxLen 10000 \
    --mgCores 8 \
    --mapCores 8 \
    --consCores 16 \
    --indexCores 16 \
    --workDir "$HOME/scratch/pang/toil_work/${OUTNAME}" \
    --maxDisk 200G

