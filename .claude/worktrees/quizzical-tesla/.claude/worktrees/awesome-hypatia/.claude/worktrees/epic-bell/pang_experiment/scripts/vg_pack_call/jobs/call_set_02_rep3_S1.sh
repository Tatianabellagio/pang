#!/bin/bash -l
#SBATCH --job-name=call_set_02_rep3_S1
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --export=ALL
#SBATCH --output=call_set_02_rep3_S1.%j.out
#SBATCH --error=call_set_02_rep3_S1.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"

export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate pang

START_TS=$(date +%s)
echo "▶ START: $(date)"

SET_NAME=set_02_rep3
SAMPLE=S1

BASE=~/scratch/pang/pang_experiment
PANG_DIR=$BASE/pangenomes/$SET_NAME

GBZ=$PANG_DIR/output/${SET_NAME}.d2.gbz
SNARLS=$PANG_DIR/output/${SET_NAME}.d2.snarls
PACK=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.pack
OUTVCF=$PANG_DIR/mapping/seedmix/$SAMPLE/${SAMPLE}.snarl_support.vcf.gz

[[ -s "$SNARLS" ]] || vg snarls "$GBZ" > "$SNARLS"

vg call -k "$PACK" -r "$SNARLS" -s "$SAMPLE" -t "$SLURM_CPUS_PER_TASK" -z "$GBZ" \
| bgzip -c > "$OUTVCF"

tabix -f -p vcf "$OUTVCF"

END_TS=$(date +%s)
echo "✅ END:   $(date)"
echo "⏱ TOTAL: $((END_TS - START_TS)) seconds"
