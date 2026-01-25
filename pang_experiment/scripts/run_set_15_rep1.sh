#!/bin/bash
#SBATCH --job-name=set_15_rep1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00
#SBATCH --output=set_15_rep1.%j.out
#SBATCH --error=set_15_rep1.%j.err

eval "$(conda shell.bash hook)"
conda activate pang

cd /home/tbellagio/scratch/pang/pang_experiment/pangenomes/set_15_rep1

JOBSTORE="jobstore"
OUTDIR="output"
OUTNAME="set_15_rep1"

rm -rf "$JOBSTORE"

cactus-pangenome \
    "$JOBSTORE" \
    seqfile.txt \
    --outDir "$OUTDIR" \
    --outName "$OUTNAME" \
    --reference Col-0 \
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

