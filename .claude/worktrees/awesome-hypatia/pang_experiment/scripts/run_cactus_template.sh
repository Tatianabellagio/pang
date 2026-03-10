#!/bin/bash
#SBATCH --job-name=CAC_NAME
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00
#SBATCH --output=CAC_NAME.%j.out
#SBATCH --error=CAC_NAME.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"

export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate pang

cd CAC_DIR

JOBSTORE="jobstore"
OUTDIR="output"
OUTNAME="CAC_NAME"

# If you want a clean rerun, keep this. If you want resume, comment it out.
rm -rf "$JOBSTORE"

export TMPDIR="/carnegie/nobackup/scratch/tbellagio/pang/tmp/${OUTNAME}"
WORKDIR="/carnegie/nobackup/scratch/tbellagio/pang/toil_work/${OUTNAME}"
mkdir -p "$TMPDIR" "$WORKDIR"

cactus-pangenome \
  "$JOBSTORE" \
  seqfile.txt \
  --outDir "$OUTDIR" \
  --outName "$OUTNAME" \
  --reference TAIR10 \
  --haplo --vcf --gfa --gbz --giraffe \
  --maxLen 10000 \
  --mgCores 8 --mapCores 8 --consCores 16 --indexCores 16 \
  --workDir "$WORKDIR" \
  --maxDisk 200G
