#!/bin/bash
#SBATCH --job-name=pack_0410
#SBATCH --output=pack_0410.out
#SBATCH --error=pack_0410.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=100G

set -e

source ~/.bashrc
mamba activate pang

GRAPH=~/scratch/pang/pang_69/upload_genome/pangraph_output/arabidopsis69filtered.d2.gbz
GAM=~/scratch/pang/run_vg_giraffe/MLFH041020180321.gam
OUT=MLFH041020180321.pack

echo "Starting vg pack"
date

vg pack \
    -x $GRAPH \
    -g $GAM \
    -o $OUT \
    -t 32

echo "Done"
date
