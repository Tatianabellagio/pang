#!/usr/bin/env bash
set -euo pipefail

ROOT=/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/pangenomes
SCRIPT_DIR=/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/scripts/snarl_quant
WORKER="$SCRIPT_DIR/snarl_qc_one_set.sh"

JOBS_DIR="$SCRIPT_DIR/jobs"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$JOBS_DIR" "$LOG_DIR"

MANIFEST="$JOBS_DIR/snarl_qc_manifest.tsv"
SUBMIT="$JOBS_DIR/submit_all_snarl_qc.sh"

# add filter column
echo -e "set\toutput_dir\top_vcf\tall_vcf\tfilter_vcf\tsbatch" > "$MANIFEST"
echo "#!/usr/bin/env bash" > "$SUBMIT"
echo "set -euo pipefail" >> "$SUBMIT"

shopt -s nullglob
for outdir in "$ROOT"/set_*/output; do
  setname="$(basename "$(dirname "$outdir")")"   # e.g. set_02_rep1

  top="$outdir/${setname}.deconstruct.top.vcf.gz"
  all="$outdir/${setname}.deconstruct.all_snarls.vcf.gz"

  # cactus/minigraph "filtered" (vcfbub) output
  filter="$outdir/${setname}.vcf.gz"

  if [[ ! -s "$top" || ! -s "$all" || ! -s "$filter" ]]; then
    echo "Skipping $setname (missing VCFs: top/all/filter)"
    echo "  top:    $top"
    echo "  all:    $all"
    echo "  filter: $filter"
    continue
  fi

  sb="$JOBS_DIR/snarl_qc_${setname}.sbatch"

  cat > "$sb" <<EOF
#!/bin/bash -l
#SBATCH --job-name=snarlqc_${setname}
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --time=02:00:00
#SBATCH --export=ALL
#SBATCH --output=$LOG_DIR/snarlqc_${setname}.%j.out
#SBATCH --error=$LOG_DIR/snarlqc_${setname}.%j.err

set -euo pipefail

eval "\$(conda shell.bash hook)"

export PYTHONPATH=\${PYTHONPATH:-}
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=\${LIBRARY_PATH:-}
export CPATH=\${CPATH:-}

conda activate pang

START_TS=\$(date +%s)
echo "▶ START: \$(date)"
echo "SET: $setname"
echo "OUTDIR: $outdir"
echo "ENV: \$CONDA_DEFAULT_ENV"
echo "bcftools: \$(command -v bcftools || echo MISSING)"
echo "tabix:    \$(command -v tabix || echo MISSING)"

echo "TOP:    $top"
echo "ALL:    $all"
echo "FILTER: $filter"

# optional: index if missing (helps bcftools index -n etc)
if [[ ! -s "$top.tbi" ]]; then tabix -f -p vcf "$top"; fi
if [[ ! -s "$all.tbi" ]]; then tabix -f -p vcf "$all"; fi
if [[ ! -s "$filter.tbi" ]]; then tabix -f -p vcf "$filter"; fi

# pass filter as 3rd VCF argument (worker must accept it)
bash "$WORKER" "$outdir" "$setname" "$top" "$all" "$filter"

END_TS=\$(date +%s)
echo "✅ END:   \$(date)"
echo "⏱ TOTAL: \$((END_TS - START_TS)) seconds"
EOF

  chmod +x "$sb"
  echo -e "${setname}\t${outdir}\t${top}\t${all}\t${filter}\t${sb}" >> "$MANIFEST"
  echo "sbatch \"$sb\"" >> "$SUBMIT"
done

chmod +x "$SUBMIT"

echo "Wrote jobs to: $JOBS_DIR"
echo "Manifest: $MANIFEST"
echo "Submit script: $SUBMIT (edit/run when ready)"
