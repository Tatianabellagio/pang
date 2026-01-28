#!/bin/bash
#SBATCH --job-name=set_50_rep2
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00
#SBATCH --output=set_50_rep2.%j.out
#SBATCH --error=set_50_rep2.%j.err

eval "$(conda shell.bash hook)"
conda activate pang

cd /home/tbellagio/scratch/pang/pang_experiment_test/pangenomes/set_50_rep2

JOBSTORE="jobstore"
OUTDIR="output"
OUTNAME="set_50_rep2"

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

