#!/bin/bash -l
#SBATCH --job-name=snarl_quant
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=logs/snarl_quant.%j.out
#SBATCH --error=logs/snarl_quant.%j.err
#SBATCH --export=ALL

set -euo pipefail
eval "$(conda shell.bash hook)"
conda activate freqk_build

BASEDIR="/home/tbellagio/scratch/pang/test_freqk/pilot_site4"
VCF="${BASEDIR}/set_05_rep1.vcf.gz"

# Optional: activate conda env if not already active
if [[ "${CONDA_DEFAULT_ENV:-}" != "pang" ]]; then
  if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
    export PYTHONPATH=${PYTHONPATH:-}
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
    export LIBRARY_PATH=${LIBRARY_PATH:-}
    export CPATH=${CPATH:-}
    conda activate pang
  else
    echo "WARNING: conda not found and CONDA_DEFAULT_ENV != pang; assuming bcftools/tabix are on PATH" >&2
  fi
fi

[[ -s "$VCF" ]] || { echo "ERROR: missing or empty VCF: $VCF" >&2; exit 1; }
[[ -s "${VCF}.tbi" ]] || { echo "ERROR: missing tabix index: ${VCF}.tbi" >&2; exit 1; }

mkdir -p "${BASEDIR}/qc_snarls"

echo "▶ START: $(date)"
echo "BASEDIR:  $BASEDIR"
echo "VCF:      $VCF"
echo "ENV:      ${CONDA_DEFAULT_ENV:-none}"
echo "bcftools: $(command -v bcftools || echo MISSING)"
echo "tabix:    $(command -v tabix || echo MISSING)"
echo

########################################
# 1) Allelicity summary
########################################
allelicity_out="${BASEDIR}/qc_snarls/qc_allelicity_summary.set_05_rep1.tsv"
echo -e "vcf\ttotal_records\tbiallelic_records\tmultiallelic_records\tmax_ALTs\ttotal_ALT_alleles" > "$allelicity_out"

stats=$(
  bcftools query -f '%ALT\n' "$VCF" \
  | awk -F',' '
      { nalt=NF; total++; alt_alleles+=nalt;
        if(nalt==1) bi++; else multi++;
        if(nalt>max) max=nalt
      }
      END{ printf("%d\t%d\t%d\t%d\t%d", total, bi, multi, max, alt_alleles) }'
)

echo -e "$(basename "$VCF")\t${stats}" >> "$allelicity_out"
echo "Wrote: $allelicity_out"
echo

########################################
# 2) Per-ALT “snarl size” table
#    - one row per ALT allele (handles multiallelic)
#    - size computed by length difference (good proxy)
########################################
out_sizes="${BASEDIR}/qc_snarls/qc_sizes_set_05_rep1.per_alt.tsv"

bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%INFO/CONFLICT\n' "$VCF" \
| awk -F'\t' '
BEGIN{
  OFS="\t";
  print "chrom","pos","id","alt_index","class","size_signed","size_bp","is_conflict","ref_len","alt_len","alt";
}
{
  chrom=$1; pos=$2; id=$3; ref=$4; alts=$5; conflict=$6;

  rl=length(ref);
  isconf = (conflict != "." && conflict != "") ? 1 : 0;

  # split ALT list for multiallelic
  n = split(alts, A, ",");

  for (i=1; i<=n; i++) {
    alt = A[i];
    al = length(alt);

    signed = al - rl;
    size = signed; if (size < 0) size = -size;

    klass="OTHER";
    if (alt ~ /^</) klass="SYMBOLIC";
    else if (rl==1 && al==1) klass="SNP";
    else if (rl==al) klass="MNP";
    else if (al>rl) klass="INS";
    else if (rl>al) klass="DEL";

    print chrom,pos,id,i,klass,signed,size,isconf,rl,al,alt;
  }
}' > "$out_sizes"

echo "Wrote: $out_sizes"
echo "✅ END: $(date)"