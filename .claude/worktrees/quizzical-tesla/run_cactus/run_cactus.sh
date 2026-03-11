#!/bin/bash
#SBATCH --job-name=cactus_pang
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00        # cactus can take days depending on cluster speed
#SBATCH --output=cactus_pang.%j.out
#SBATCH --error=cactus_pang.%j.err

# Load your conda/mamba environment
eval "$(conda shell.bash hook)"
mamba activate pang   # <- your cactus environment

# Go to directory with your seqfile + FASTAs
cd ~/scratch/pang/pang_69/upload_genome

# Define output directories
JOBSTORE="jobstore_pangraph"
OUTDIR="pangraph_output"
OUTNAME="arabidopsis69filtered"

# Reference genome (must be chromosome-scale)
REFERENCE="Col-0"

# Remove previous jobstore to avoid Toil errors
rm -rf $JOBSTORE

# Run cactus-pangenome
cactus-pangenome \
    $JOBSTORE \
    seqfile.txt \
    --outDir $OUTDIR \
    --outName $OUTNAME \
    --reference $REFERENCE \
    --maxLen 10000 \
    --mgCores 4 \
    --mapCores 2 \
    --consCores 8 \
    --indexCores 8 \
    --haplo \
    --vcf \
    --gfa \
    --gbz \
    --giraffe

echo "Cactus pangenome run completed."
