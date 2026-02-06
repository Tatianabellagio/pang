#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   snarl_qc_one_set.sh BASEDIR PREFIX [TOP_VCF] [ALL_VCF] [FILTER_VCF]
# Example:
#   snarl_qc_one_set.sh /.../pangenomes/set_02_rep1/output set_02_rep1
#   snarl_qc_one_set.sh /.../output set_02_rep1 top.vcf.gz all.vcf.gz filter.vcf.gz

BASEDIR="${1:?need BASEDIR}"
PREFIX="${2:?need PREFIX (e.g. set_02_rep1)}"

# Allow overriding inputs from job script; otherwise use defaults
TOP_VCF="${3:-$BASEDIR/${PREFIX}.deconstruct.top.vcf.gz}"
ALL_VCF="${4:-$BASEDIR/${PREFIX}.deconstruct.all_snarls.vcf.gz}"
FILTER_VCF="${5:-$BASEDIR/${PREFIX}.vcf.gz}"   # cactus/minigraph "filtered" vcfbub output

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

# Build list of VCFs to process
VCFS=("$TOP_VCF" "$ALL_VCF" "$FILTER_VCF")

for f in "${VCFS[@]}"; do
  if [[ ! -s "$f" ]]; then
    echo "ERROR: missing or empty: $f" >&2
    exit 1
  fi
done

mkdir -p "$BASEDIR/qc"

echo "▶ START: $(date)"
echo "BASEDIR: $BASEDIR"
echo "PREFIX:  $PREFIX"
echo "ENV:     ${CONDA_DEFAULT_ENV:-none}"
echo "bcftools: $(command -v bcftools || echo MISSING)"
echo "tabix:    $(command -v tabix || echo MISSING)"
echo "TOP_VCF:    $TOP_VCF"
echo "ALL_VCF:    $ALL_VCF"
echo "FILTER_VCF: $FILTER_VCF"

########################################
# 1) Allelicity summary
########################################
allelicity_out="$BASEDIR/qc/qc_allelicity_summary.${PREFIX}.tsv"
echo -e "vcf\ttotal_records\tbiallelic_records\tmultiallelic_records\tmax_ALTs\ttotal_ALT_alleles" > "$allelicity_out"

for vcf_path in "${VCFS[@]}"; do
  vcf_name="$(basename "$vcf_path")"

  stats=$(bcftools query -f '%ALT\n' "$vcf_path" \
    | awk -F',' '
      { nalt=NF; total++; alt_alleles+=nalt;
        if(nalt==1) bi++; else multi++;
        if(nalt>max) max=nalt
      }
      END{ printf("%d\t%d\t%d\t%d\t%d", total, bi, multi, max, alt_alleles) }')

  echo -e "$vcf_name\t$stats" >> "$allelicity_out"
done

echo "Wrote: $allelicity_out"

########################################
# 2) Split to biallelic
########################################
for vcf_path in "${VCFS[@]}"; do
  vcf_name="$(basename "$vcf_path")"
  out_bi="$BASEDIR/qc/${vcf_name%.vcf.gz}.biallelic.norm.vcf.gz"

  # keep your original behavior; this is actually split + normalize representation
  bcftools norm -m -any -Oz -o "$out_bi" "$vcf_path"
  tabix -f -p vcf "$out_bi"

  echo "Wrote: $out_bi"
done

########################################
# 3) Per-record descriptions (on biallelic VCFs)
########################################
for vcf_path in "${VCFS[@]}"; do
  vcf_name="$(basename "$vcf_path")"
  base="${vcf_name%.vcf.gz}"   # works regardless of naming
  vcf_bi="$BASEDIR/qc/${base}.biallelic.norm.vcf.gz"
  out_sizes="$BASEDIR/qc/qc_sizes_biallelic.${base}.tsv"

  bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%INFO/CONFLICT\n' "$vcf_bi" \
  | awk -F'\t' 'BEGIN{OFS="\t"; print "chrom","pos","id","class","size_signed","size_bp","is_conflict"}
  {
    ref=$4; alt=$5; conflict=$6;

    rl=length(ref); al=length(alt);
    signed = al-rl;
    size = signed; if(size<0) size=-size;

    klass="OTHER";
    if(alt ~ /^</) klass="SYMBOLIC";
    else if(rl==1 && al==1) klass="SNP";
    else if(rl==al) klass="MNP";
    else if(al>rl) klass="INS";
    else if(rl>al) klass="DEL";

    isconf = (conflict != "." && conflict != "") ? 1 : 0;

    print $1,$2,$3,klass,signed,size,isconf;
  }' > "$out_sizes"

  echo "Wrote: $out_sizes"
done

echo "✅ END: $(date)"
