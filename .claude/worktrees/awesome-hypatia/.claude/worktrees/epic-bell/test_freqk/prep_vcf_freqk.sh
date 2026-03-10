#!/bin/bash -l
#SBATCH --job-name=FREQK_PREP_VCF
#SBATCH --partition=bse
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --export=ALL
#SBATCH --output=FREQK_PREP_VCF.%j.out
#SBATCH --error=FREQK_PREP_VCF.%j.err

set -euo pipefail

eval "$(conda shell.bash hook)"

# Keep env clean (you’ve used this pattern before)
export PYTHONPATH=${PYTHONPATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LIBRARY_PATH=${LIBRARY_PATH:-}
export CPATH=${CPATH:-}

conda activate pang  # has bcftools + tabix

WORK=/home/tbellagio/scratch/pang/test_freqk/run_set_02_rep1_S1
cd "$WORK"

VCF_IN=set_02_rep1.deconstruct.top.vcf.gz
VCF_OUT=set_02_rep1.deconstruct.top.renamed.vcf.gz

cat > contig_rename.txt <<'EOF'
TAIR10#0#Chr1	Chr1
TAIR10#0#Chr2	Chr2
TAIR10#0#Chr3	Chr3
TAIR10#0#Chr4	Chr4
TAIR10#0#Chr5	Chr5
EOF

bcftools annotate --rename-chrs contig_rename.txt -Oz -o "$VCF_OUT" "$VCF_IN"
tabix -f -p vcf "$VCF_OUT"

echo "✅ Renamed+indexed VCF: $WORK/$VCF_OUT"
echo "Contigs:"
tabix -l "$VCF_OUT" | head
