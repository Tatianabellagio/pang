#!/bin/bash
#SBATCH --job-name=giraffe_MLFH041020180321
#SBATCH --output=giraffe_MLFH041020180321.out
#SBATCH --error=giraffe_MLFH041020180321.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=120G

set -e

echo "Starting vg giraffe on sample MLFH041020180321"
date

# Activate environment
source ~/.bashrc
mamba activate pang     # your environment with vg

# Paths to indexes
GRAPH=~/scratch/pang/pang_69/upload_genome/pangraph_output/arabidopsis69filtered.d2.gbz
DIST=~/scratch/pang/pang_69/upload_genome/pangraph_output/arabidopsis69filtered.d2.dist
MIN=~/scratch/pang/pang_69/upload_genome/pangraph_output/arabidopsis69filtered.d2.shortread.withzip.min
ZIP=~/scratch/pang/pang_69/upload_genome/pangraph_output/arabidopsis69filtered.d2.shortread.zipcodes

# Input reads
R1=~/scratch/pang/grenenet_reads/grenenet-phase1/2021-05-03-ath-release-07/raw_data/MLFH041020180321/*_1.fq.gz
R2=~/scratch/pang/grenenet_reads/grenenet-phase1/2021-05-03-ath-release-07/raw_data/MLFH041020180321/*_2.fq.gz

# Output
OUT=MLFH041020180321.gam

# Run giraffe
vg giraffe \
    -Z $GRAPH \
    -d $DIST \
    -m $MIN \
    -z $ZIP \
    -f $R1 \
    -f $R2 \
    -t 32 \
    > $OUT

echo "Done."
date
