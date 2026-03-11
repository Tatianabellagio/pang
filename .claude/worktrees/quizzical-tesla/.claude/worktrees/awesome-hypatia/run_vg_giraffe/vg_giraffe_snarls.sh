#!/bin/bash
#SBATCH --job-name=snarls_0410
#SBATCH --output=snarls_0410.out
#SBATCH --error=snarls_0410.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=150G

set -e

source ~/.bashrc
mamba activate pang

GRAPH=~/scratch/pang/pangraph_output/arabidopsis69filtered.d2.gbz
OUT=arabidopsis69filtered.d2.snarls

echo "Starting vg snarls"
date

vg snarls \
    -t 16 \
    $GRAPH \
    > $OUT

echo "Done"
date
