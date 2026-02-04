#!/usr/bin/env bash
set -euo pipefail

ROOT=/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/pangenomes
SCRIPT_DIR=/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/scripts/snarl_deconstruct

LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

# Two job folders
JOBS_ALL="$SCRIPT_DIR/jobs_deconstruct_all"
JOBS_TOP="$SCRIPT_DIR/jobs_deconstruct_top"
mkdir -p "$JOBS_ALL" "$JOBS_TOP"

# Manifests + submit scripts
MAN_ALL="$JOBS_ALL/deconstruct_all_manifest.tsv"
SUB_ALL="$JOBS_ALL/submit_all_deconstruct_all.sh"

MAN_TOP="$JOBS_TOP/deconstruct_top_manifest.tsv"
SUB_TOP="$JOBS_TOP/submit_all_deconstruct_top.sh"

echo -e "set\toutput_dir\tgbz\tsnarls\tout_vcf\tsbatch" > "$MAN_ALL"
echo -e "set\toutput_dir\tgbz\tsnarls\tout_vcf\tsbatch" > "$MAN_TOP"

echo "#!/usr/bin/env bash" > "$SUB_ALL"
echo "set -euo pipefail" >> "$SUB_ALL"

echo "#!/usr/bin/env bash" > "$SUB_TOP"
echo "set -euo pipefail" >> "$SUB_TOP"

chmod +x "$SUB_ALL" "$SUB_TOP"

# Resources
TIME_LIMIT="02:00:00"
CPUS="16"
MEM="96G"
REFPREFIX="TAIR10"

shopt -s nullglob
for outdir in "$ROOT"/set_*/output; do
  setname="$(basename "$(dirname "$outdir")")"   # e.g. set_02_rep1

  GRAPH="$outdir/${setname}.gbz"
  SNARLS="$outdir/${setname}.snarls"

  if [[ ! -s "$GRAPH" || ! -s "$SNARLS" ]]; then
    echo "Skipping $setname (missing GBZ or snarls)"
    continue
  fi

  ############################
  # ALL snarls deconstruct job
  ############################
  OUT_ALL="$outdir/${setname}.deconstruct.all_snarls.vcf.gz"
  SB_ALL="$JOBS_ALL/deconstruct_all_${setname}.sbatch"

  cat > "$SB_ALL" <<EOF
#!/bin/bash -l
#SBATCH --job-name=decon_all_${setname}
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=${CPUS}
#SBATCH --mem=${MEM}
#SBATCH --time=${TIME_LIMIT}
#SBATCH --export=ALL
#SBATCH --output=$LOG_DIR/decon_all_${setname}.%j.out
#SBATCH --error=$LOG_DIR/decon_all_${setname}.%j.err

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
echo "MODE: all"
echo "ENV: \$CONDA_DEFAULT_ENV"
echo "vg:    \$(command -v vg || echo MISSING)"
echo "bgzip: \$(command -v bgzip || echo MISSING)"
echo "tabix: \$(command -v tabix || echo MISSING)"

cd "$outdir"

# Sanity check inputs
ls -lh "$GRAPH" "$SNARLS" >/dev/null

vg deconstruct \\
  -a \\
  -P "$REFPREFIX" \\
  -r "$SNARLS" \\
  -K \\
  -t "\${SLURM_CPUS_PER_TASK:-${CPUS}}" \\
  "$GRAPH" \\
| bgzip -c > "$OUT_ALL"

tabix -f -p vcf "$OUT_ALL"

END_TS=\$(date +%s)
echo "✅ END:   \$(date)"
echo "⏱ TOTAL: \$((END_TS - START_TS)) seconds"
echo "Wrote: $OUT_ALL"
EOF

  chmod +x "$SB_ALL"
  echo -e "${setname}\t${outdir}\t${GRAPH}\t${SNARLS}\t${OUT_ALL}\t${SB_ALL}" >> "$MAN_ALL"
  echo "sbatch \"$SB_ALL\"" >> "$SUB_ALL"

  ############################
  # TOP snarls deconstruct job
  ############################
  OUT_TOP="$outdir/${setname}.deconstruct.top.vcf.gz"
  SB_TOP="$JOBS_TOP/deconstruct_top_${setname}.sbatch"

  cat > "$SB_TOP" <<EOF
#!/bin/bash -l
#SBATCH --job-name=decon_top_${setname}
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=${CPUS}
#SBATCH --mem=${MEM}
#SBATCH --time=${TIME_LIMIT}
#SBATCH --export=ALL
#SBATCH --output=$LOG_DIR/decon_top_${setname}.%j.out
#SBATCH --error=$LOG_DIR/decon_top_${setname}.%j.err

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
echo "MODE: top"
echo "ENV: \$CONDA_DEFAULT_ENV"
echo "vg:    \$(command -v vg || echo MISSING)"
echo "bgzip: \$(command -v bgzip || echo MISSING)"
echo "tabix: \$(command -v tabix || echo MISSING)"

cd "$outdir"

# Sanity check inputs
ls -lh "$GRAPH" "$SNARLS" >/dev/null

vg deconstruct \\
  -P "$REFPREFIX" \\
  -r "$SNARLS" \\
  -K \\
  -t "\${SLURM_CPUS_PER_TASK:-${CPUS}}" \\
  "$GRAPH" \\
| bgzip -c > "$OUT_TOP"

tabix -f -p vcf "$OUT_TOP"

END_TS=\$(date +%s)
echo "✅ END:   \$(date)"
echo "⏱ TOTAL: \$((END_TS - START_TS)) seconds"
echo "Wrote: $OUT_TOP"
EOF

  chmod +x "$SB_TOP"
  echo -e "${setname}\t${outdir}\t${GRAPH}\t${SNARLS}\t${OUT_TOP}\t${SB_TOP}" >> "$MAN_TOP"
  echo "sbatch \"$SB_TOP\"" >> "$SUB_TOP"
done

echo
echo "✅ Wrote ALL jobs to: $JOBS_ALL"
echo "   Manifest: $MAN_ALL"
echo "   Submit:   $SUB_ALL"
echo
echo "✅ Wrote TOP jobs to: $JOBS_TOP"
echo "   Manifest: $MAN_TOP"
echo "   Submit:   $SUB_TOP"
