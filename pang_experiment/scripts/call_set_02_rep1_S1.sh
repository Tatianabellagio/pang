#!/bin/bash
#SBATCH --job-name=CALL_set_02_rep1_S1
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=CALL_set_02_rep1_S1.%j.out
#SBATCH --error=CALL_set_02_rep1_S1.%j.err

set -eo pipefail

eval "$(conda shell.bash hook)"
conda activate pang
set -u

SET_NAME=set_02_rep1
SAMPLE=S1
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

