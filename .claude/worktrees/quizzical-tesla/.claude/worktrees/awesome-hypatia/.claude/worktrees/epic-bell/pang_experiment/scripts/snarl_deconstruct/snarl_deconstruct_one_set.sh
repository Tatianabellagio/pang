#!/usr/bin/env bash
set -euo pipefail

outdir="${1:?usage: snarl_deconstruct_one_set.sh OUTDIR SETNAME [mode]}"
setname="${2:?usage: snarl_deconstruct_one_set.sh OUTDIR SETNAME [mode]}"
mode="${3:-all}"   # all | top

GRAPH="$outdir/${setname}.gbz"
REFPREFIX="TAIR10"

# default snarls file
SNARLS="$outdir/${setname}.snarls"

# Optional: if you have a special “top snarls” file, set it here
TOP_SNARLS="$outdir/${setname}.top.snarls"   # change if your naming differs

if [[ "$mode" == "top" ]]; then
  SNARLS="$TOP_SNARLS"
  OUT="$outdir/${setname}.deconstruct.top_snarls.vcf.gz"
else
  OUT="$outdir/${setname}.deconstruct.all_snarls.vcf.gz"
fi

ls -lh "$GRAPH" "$SNARLS" >/dev/null

THREADS="${SLURM_CPUS_PER_TASK:-1}"

vg deconstruct \
  -a \
  -P "$REFPREFIX" \
  -r "$SNARLS" \
  -K \
  -t "$THREADS" \
  "$GRAPH" \
| bgzip -c > "$OUT"

tabix -f -p vcf "$OUT"

echo "Wrote: $OUT"
