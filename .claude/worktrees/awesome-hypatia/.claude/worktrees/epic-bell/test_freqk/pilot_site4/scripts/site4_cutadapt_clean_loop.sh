#!/bin/bash -l
#SBATCH --job-name=SITE4_CUTADAPT
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=logs/SITE4_CUTADAPT.%j.out
#SBATCH --error=logs/SITE4_CUTADAPT.%j.err
#SBATCH --export=ALL

set -euo pipefail

eval "$(conda shell.bash hook)"
conda activate pang

BASE=/home/tbellagio/scratch/pang/test_freqk/pilot_site4
cd "$BASE"

mkdir -p logs cleaned

SEQ="ATCATACACATGACATCAAGTCATATTCGACTCCAAAACACTAACCAACC"
THREADS="${SLURM_CPUS_PER_TASK:-8}"

echo "Node: $(hostname)"
echo "CWD:  $(pwd)"
echo "Threads: $THREADS"
echo

shopt -s nullglob
R1S=(trimmed/site4_*.R1.P.fq.gz)
if [[ ${#R1S[@]} -eq 0 ]]; then
  echo "No inputs found: trimmed/site4_*.R1.P.fq.gz" >&2
  exit 1
fi

# keep deterministic order
IFS=$'\n' R1S=($(printf "%s\n" "${R1S[@]}" | sort))
unset IFS

for R1 in "${R1S[@]}"; do
  R2="${R1/.R1.P.fq.gz/.R2.P.fq.gz}"
  id=$(basename "$R1" .R1.P.fq.gz)

  OUT1="cleaned/${id}.R1.clean.fq.gz"
  OUT2="cleaned/${id}.R2.clean.fq.gz"

  echo "==== $id ===="
  echo "R1=$R1"
  echo "R2=$R2"

  [[ -s "$R1" ]] || { echo "Missing R1: $R1" >&2; exit 1; }
  [[ -s "$R2" ]] || { echo "Missing R2: $R2" >&2; exit 1; }

  # skip if already done
  if [[ -s "$OUT1" && -s "$OUT2" ]]; then
    echo "Outputs exist, skipping: $OUT1 $OUT2"
    echo
    continue
  fi

  cutadapt -j "$THREADS" \
    -g "^${SEQ}" \
    -g "^CTTATACTCA${SEQ}" \
    -g "^GTTATACTCA${SEQ}" \
    -G "^${SEQ}" \
    -G "^CTTATACTCA${SEQ}" \
    -G "^GTTATACTCA${SEQ}" \
    -o "$OUT1" -p "$OUT2" \
    "$R1" "$R2" \
    > "logs/${id}.cutadapt.out" 2> "logs/${id}.cutadapt.err"

  echo "Wrote: $OUT1 $OUT2"
  echo
done

echo "All done."
