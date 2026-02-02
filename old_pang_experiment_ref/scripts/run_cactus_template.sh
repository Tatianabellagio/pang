#!/bin/bash
#SBATCH --job-name=CAC_NAME
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00
#SBATCH --output=CAC_NAME.%j.out
#SBATCH --error=CAC_NAME.%j.err

eval "$(conda shell.bash hook)"
conda activate pang

cd CAC_DIR

JOBSTORE="jobstore"
OUTDIR="output"
OUTNAME="CAC_NAME"

rm -rf "$JOBSTORE"

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
    --indexCores 16

