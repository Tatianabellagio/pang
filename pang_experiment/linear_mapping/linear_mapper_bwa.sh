#!/bin/bash
#SBATCH --job-name=MAP_LINEAR_SAMPLE
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=08:00:00
#SBATCH --output=MAP_LINEAR_%j.out
#SBATCH --error=MAP_LINEAR_%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate pang

THREADS=16
REF=~/scratch/pang/pang_experiment/linear_mapping/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa
READ_DIR=~/scratch/pang/grenenet_reads/seed_mix

SAMPLE=S1   # change or template this

OUTDIR=~/scratch/pang/pang_experiment/linear_mapping/results/$SAMPLE
mkdir -p $OUTDIR

R1=$READ_DIR/${SAMPLE}-1.1_P.fq.gz
R2=$READ_DIR/${SAMPLE}-1.2_P.fq.gz

echo "▶ Mapping $SAMPLE to TAIR10"
date

bwa-mem2 mem \
  -t $THREADS \
  $REF \
  $R1 $R2 \
| samtools sort -@ $((THREADS/2)) \
  -o $OUTDIR/${SAMPLE}.sorted.bam

samtools index $OUTDIR/${SAMPLE}.sorted.bam

echo "▶ Stats"
samtools flagstat $OUTDIR/${SAMPLE}.sorted.bam \
  > $OUTDIR/${SAMPLE}.flagstat.txt

samtools stats $OUTDIR/${SAMPLE}.sorted.bam \
  > $OUTDIR/${SAMPLE}.stats.txt

date
echo "✅ DONE"
