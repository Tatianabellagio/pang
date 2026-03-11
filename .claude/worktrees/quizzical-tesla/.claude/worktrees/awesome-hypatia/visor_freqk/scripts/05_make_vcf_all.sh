#!/bin/bash
#SBATCH --job-name=make_vcf_all
#SBATCH --output=logs/05_make_vcf_all_%j.out
#SBATCH --error=logs/05_make_vcf_all_%j.err
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
VCF_DIR=/home/tbellagio/scratch/pang/visor_freqk/data/vcf
BED_DIR=/home/tbellagio/scratch/pang/visor_freqk/data/beds
mkdir -p "${VCF_DIR}" logs

CHROM="Chr1"

# All deletions start at the same position (BED 0-based start = 10000000)
# VCF anchor is always one base before in 1-based coords
ANCHOR_POS=9999999

declare -A DEL_SIZES=(
  ["100bp"]=100
  ["500bp"]=500
  ["1kb"]=1000
  ["5kb"]=5000
  ["10kb"]=10000
)

for SIZE in "${!DEL_SIZES[@]}"; do
  DEL_LEN=${DEL_SIZES[$SIZE]}
  
  # Calculate coordinates
  # BED: Chr1 10000000 10000000+DEL_LEN (0-based half-open)
  # VCF: POS=9999999 (anchor), DEL_END=10000000+DEL_LEN (1-based)
  POS=${ANCHOR_POS}
  DEL_END=$((10000000 + DEL_LEN))
  SVLEN=$((DEL_LEN + 1))  # anchor base + deleted bases
  
  VCF_RAW="${VCF_DIR}/del_${SIZE}.vcf"
  VCF_GZ="${VCF_DIR}/del_${SIZE}.vcf.gz"

  echo "[$(date)] Building VCF for ${SIZE}: POS=${POS}, DEL_END=${DEL_END}, SVLEN=${SVLEN}"

  # Extract REF sequence (anchor + deleted region)
  REF_SEQ=$(samtools faidx "${REF}" "${CHROM}:${POS}-${DEL_END}" | grep -v "^>" | tr -d '\n')
  ALT_SEQ="${REF_SEQ:0:1}"  # anchor base only
  
  echo "[$(date)]   REF length: ${#REF_SEQ}, ALT: ${ALT_SEQ}"

  cat > "${VCF_RAW}" << VCFEOF
##fileformat=VCFv4.2
##source=simulated_visor
##FILTER=<ID=PASS,Description="All filters passed">
##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">
##INFO=<ID=SVLEN,Number=1,Type=Integer,Description="Difference in length between REF and ALT alleles">
##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant">
##contig=<ID=${CHROM}>
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
VCFEOF

  echo -e "${CHROM}\t${POS}\t.\t${REF_SEQ}\t${ALT_SEQ}\t1000\tPASS\tSVTYPE=DEL;SVLEN=-${SVLEN};END=${DEL_END}" >> "${VCF_RAW}"

  bgzip -f "${VCF_RAW}"
  tabix "${VCF_GZ}"

  echo "[$(date)] Done: ${VCF_GZ}"
done

echo "[$(date)] All VCFs created successfully"