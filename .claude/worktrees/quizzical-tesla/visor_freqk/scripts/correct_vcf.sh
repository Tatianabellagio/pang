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
# REF = anchor base + deleted sequence (anchor at POS, deleted bases POS+1 to DEL_END)
# ALT = anchor base only
# Output: data/vcf/del_1kb.vcf.gz (bgzipped + tabix indexed)
#

# Coordinates (aligned to VISOR haplotype junction):
#   BED 0-based:     Chr1 10000000 10001000
#   VISOR deletes:   1-based 10000001-10001000, sequence resumes at 10001001
#   VCF anchor:      POS=9999999 (last base before deletion, 1-based)
#   REF:             Chr1:9999999-10001000 (anchor + deleted bases)
#   ALT:             anchor base only (T)
# =============================================================================
set -euo pipefail
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

REF=/home/tbellagio/scratch/pang/visor_freqk/data/reference/Chr1.fa
VCF_DIR=/home/tbellagio/scratch/pang/visor_freqk/data/vcf
mkdir -p "${VCF_DIR}" logs

CHROM="Chr1"
POS=9999999        # anchor base (last base before deletion, 1-based)
DEL_END=10001000   # last deleted base (1-based)
SVLEN=1001

echo "[$(date)] Extracting REF sequence at ${CHROM}:${POS}-${DEL_END}"
REF_SEQ=$(samtools faidx "${REF}" "${CHROM}:${POS}-${DEL_END}" | grep -v "^>" | tr -d '\n')
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
bgzip -f "${VCF_RAW}"
tabix "${VCF_DIR}/del_1kb.vcf.gz"
rm -f "${VCF_RAW}"

echo "[$(date)] Done. VCF: ${VCF_DIR}/del_1kb.vcf.gz"
echo "[$(date)] Sanity check - VCF record:"
bcftools view "${VCF_DIR}/del_1kb.vcf.gz" | grep -v "^#" | \
awk '{print "POS="$2, "REF_len="length($4), "ALT="$5}'
echo "[$(date)] Sanity check - haplotype junction (should match ALT context):"
samtools faidx \
/home/tbellagio/scratch/pang/visor_freqk/data/haplotypes/_clone_DEL_1kb/h1.fa \
Chr1:9999985-10000016
echo "[$(date)] Sanity check - reference after deletion (should match haplotype post-junction):"