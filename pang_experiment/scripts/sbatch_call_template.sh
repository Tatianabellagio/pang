#!/bin/bash
#SBATCH --job-name=CALL_SET_SAMPLE
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=CALL_SET_SAMPLE.%j.out
#SBATCH --error=CALL_SET_SAMPLE.%j.err

set -eo pipefail

eval "$(conda shell.bash hook)"
conda activate pang
set -u

SET_NAME=SET_NAME_HERE
SAMPLE=SAMPLE_HERE
THREADS=8

BASE=~/scratch/pang/pang_experiment
PANG_DIR=$BASE/pangenomes/$SET_NAME

GBZ=$PANG_DIR/output/${SET_NAME}.d2.gbz
SNARLS=$PANG_DIR/output/${SET_NAME}.snarls
PACK=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.pack
OUTVCF=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.snarl_support.vcf

vg call \
  -k $PACK \
  -r $SNARLS \
  -s $SAMPLE \
  -t $THREADS \
  $GBZ \
  > $OUTVCF

