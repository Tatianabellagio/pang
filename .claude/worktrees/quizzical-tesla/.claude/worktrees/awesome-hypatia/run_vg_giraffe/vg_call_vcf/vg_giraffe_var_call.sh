#!/bin/bash
#SBATCH --job-name=call_0410
#SBATCH --output=call_0410.out
#SBATCH --error=call_0410.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=120G

set -e

source ~/.bashrc
mamba activate pang

GRAPH=~/scratch/pang/pangraph_output/arabidopsis69filtered.d2.gbz
PACK=~/scratch/pang/run_vg_giraffe/MLFH041020180321.pack
SNARLS=~/scratch/pang/run_vg_giraffe/arabidopsis69filtered.d2.snarls
OUT=MLFH041020180321.traversals.gaf

echo "Starting vg call"
date

vg call \
    $GRAPH \
    -k $PACK \
    -r $SNARLS \
    -a \
    -t 32 \
    > sample.vcf

echo "Done"
date
