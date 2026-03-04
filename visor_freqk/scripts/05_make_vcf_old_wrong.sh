#!/bin/bash
#SBATCH --job-name=make_vcf
#SBATCH --output=logs/05_make_vcf_%j.out
#SBATCH --error=logs/05_make_vcf_%j.err
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
# =============================================================================
# 05_make_vcf.sh
# Purpose: Create a sequence-resolved VCF for the 1kb deletion at Chr1:10000000
# REF = anchor base + deleted sequence (e.g. ATGC...1000bp)
# ALT = anchor base only
# Output: data/vcf/del_1kb.vcf.gz (bgzipped + tabix indexed)
# =============================================================================
set -euo pipefail
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
VCF_DIR=/home/tbellagio/scratch/pang/visor_freqk/data/vcf
mkdir -p "${VCF_DIR}" logs

# Deletion coordinates (1-based, matching BED 0-based: 10000000-10001000)
CHROM="Chr1"
POS=10000000       # anchor base position (1-based)
DEL_START=10000001 # first deleted base (1-based)
DEL_END=10001000   # last deleted base (1-based, inclusive)
SVLEN=1000

echo "[$(date)] Extracting REF sequence at ${CHROM}:${POS}-${DEL_END}"

# REF = anchor base + deleted sequence (POS to DEL_END, inclusive)
REF_SEQ=$(samtools faidx "${REF}" "${CHROM}:${POS}-${DEL_END}" | grep -v "^>" | tr -d '\n')

# ALT = anchor base only (first base of REF_SEQ)
ALT_SEQ="${REF_SEQ:0:1}"

echo "[$(date)] REF length: ${#REF_SEQ}, ALT: ${ALT_SEQ}"

VCF_RAW="${VCF_DIR}/del_1kb.vcf"

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

echo "[$(date)] Sorting, bgzipping and indexing VCF"
bcftools sort "${VCF_RAW}" -o "${VCF_RAW}.sorted.vcf"
bgzip -f "${VCF_RAW}.sorted.vcf" -o "${VCF_DIR}/del_1kb.vcf.gz"
tabix -p vcf "${VCF_DIR}/del_1kb.vcf.gz"

rm -f "${VCF_RAW}"

echo "[$(date)] Done. VCF: ${VCF_DIR}/del_1kb.vcf.gz"
bcftools view "${VCF_DIR}/del_1kb.vcf.gz" | tail -3