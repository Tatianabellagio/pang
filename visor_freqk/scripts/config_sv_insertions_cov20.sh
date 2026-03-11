#!/bin/bash

# Example config for insertion experiments (not yet wired into all scripts)

WORK=/home/tbellagio/scratch/pang/visor_freqk
REF=${WORK}/data/reference/Chr1.fa
BEDS=${WORK}/data/beds/ins
HAPS=${WORK}/data/haplotypes/ins
READS=${WORK}/data/reads/ins
VCF_DIR=${WORK}/data/vcf/ins
RESULTS=${WORK}/results/ins

SV_TYPE="INS"
CHROM="Chr1"

# For insertions you'd typically specify the insertion site (0-based) and lengths
SV_START_0=10000000

declare -A INS_SIZES=(
  ["100bp"]=100
  ["500bp"]=500
  ["1kb"]=1000
  ["5kb"]=5000
  ["10kb"]=10000
)

FREQ=0.50
COVERAGE=20
ERROR_RATE=0.001
WT_CLONE=${HAPS}/_clone_WT

K=31
FREQK=/home/tbellagio/scratch/pang/test_freqk/freqk/target/release/freqk

