#!/bin/bash
set -euo pipefail

BASE="$HOME/scratch/pang/pang_experiment"
GENOMES="$BASE/genomes"
SETS="$BASE/sets"
PANG="$BASE/pangenomes"
SCRIPTS="$BASE/scripts"

mkdir -p "$GENOMES" "$SETS" "$PANG" "$SCRIPTS"

echo "✔ Created directory structure under $BASE"


#########################################
# 1. COPY GENOMES (skip empty) 
#########################################
SRC="$HOME/scratch/pang/pang_69/upload_genome"

echo "Copying FASTA genomes (skipping empty files)..."

for f in "$SRC"/*.fasta; do
    if [[ -s "$f" ]]; then
        cp "$f" "$GENOMES/"
    else
        echo "⚠️ Skipping EMPTY genome: $(basename "$f")"
    fi
done

echo "✔ Finished copying genomes."


#########################################
# 2. DEFINE OVERLAP ACCESSIONS
#########################################
OVERLAP=(
Kar-1
Sus-1
Zal-1
Cvi-0
Ms-0
Can-0
Ct-1
Mh-0
No-0
Oy-0
Rubezhnoe-1
Stw-0
St-0
Altai-5
Anz-0
Qar-8a
Toufl-1
Dog-4
)

echo "✔ Loaded overlap list (${#OVERLAP[@]} accessions)"


#########################################
# 3. COMPUTE NON-OVERLAP LIST
#########################################
ALL_GENOMES=($(ls "$GENOMES"/*.fasta | xargs -n1 basename | sed 's/.fasta//'))

# Remove Col-0 from selection pool
ALL_NO_COL=($(printf "%s\n" "${ALL_GENOMES[@]}" | grep -v "^Col-0$"))

NON_OVERLAP=()
for g in "${ALL_NO_COL[@]}"; do
    if ! printf "%s\n" "${OVERLAP[@]}" | grep -q "^$g$"; then
        NON_OVERLAP+=("$g")
    fi
done

echo "✔ Non-overlap list computed: ${#NON_OVERLAP[@]} genomes"


#########################################
# 4. DEFINE SET SIZES & REPS
#########################################
declare -A SIZES=(
    [set_02]=2
    [set_05]=5
    [set_10]=10
    [set_15]=15
    [set_18]=18
    [set_30]=30
)

declare -A REPS=(
    [set_02]=3
    [set_05]=3
    [set_10]=3
    [set_15]=3
    [set_18]=1
    [set_30]=3
    [set_all]=3
)


#########################################
# 5. GENERATE SET FILES
#########################################
echo "Generating accession subset files..."

for setname in "${!SIZES[@]}"; do
    size=${SIZES[$setname]}
    reps=${REPS[$setname]}

    for rep in $(seq 1 "$reps"); do
        outfile="$SETS/${setname}_rep${rep}.txt"

        if [[ "$setname" == "set_18" ]]; then
            # fixed set = 18 overlap + Col-0
            printf "Col-0\n" > "$outfile"
            printf "%s\n" "${OVERLAP[@]}" >> "$outfile"
            continue
        fi

        # random subset from overlap list
        chosen=($(printf "%s\n" "${OVERLAP[@]}" | shuf -n "$size"))

        printf "Col-0\n" > "$outfile"
        printf "%s\n" "${chosen[@]}" >> "$outfile"
    done
done

# FULL set
for rep in $(seq 1 "${REPS["set_all"]}"); do
    printf "%s\n" "${ALL_GENOMES[@]}" > "$SETS/set_all_rep${rep}.txt"
done

echo "✔ Created all set files in $SETS"


#########################################
# 6. BUILD seqfile generator script
#########################################
cat > "$SCRIPTS/build_seqfile.py" << 'EOF'
#!/usr/bin/env python3
import sys, os

set_file = sys.argv[1]
genome_dir = sys.argv[2]
out_file = sys.argv[3]

with open(set_file) as f:
    accs = [l.strip() for l in f if l.strip()]

with open(out_file, "w") as out:
    for acc in accs:
        fasta = f"{genome_dir}/{acc}.fasta"
        if not os.path.isfile(fasta):
            raise FileNotFoundError(f"Missing FASTA: {fasta}")
        out.write(f"{acc}\t{fasta}\n")
EOF

chmod +x "$SCRIPTS/build_seqfile.py"

echo "✔ build_seqfile.py written"


#########################################
# 7. SBATCH TEMPLATE
#########################################
cat > "$SCRIPTS/run_cactus_template.sh" << 'EOF'
#!/bin/bash
#SBATCH --job-name=CAC_NAME
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=5-10:00:00
#SBATCH --output=CAC_NAME.%j.out
#SBATCH --error=CAC_NAME.%j.err

eval "$(conda shell.bash hook)"
conda activate pang

cd CAC_DIR

JOBSTORE="jobstore"
OUTDIR="output"
OUTNAME="CAC_NAME"

rm -rf "$JOBSTORE"

cactus-pangenome \
    "$JOBSTORE" \
    seqfile.txt \
    --outDir "$OUTDIR" \
    --outName "$OUTNAME" \
    --reference Col-0 \
    --haplo \
    --vcf \
    --gfa \
    --gbz \
    --giraffe \
    --maxLen 10000 \
    --mgCores 8 \
    --mapCores 8 \
    --consCores 16 \
    --indexCores 16

EOF

echo "✔ run_cactus_template.sh created"


#########################################
# 8. GENERATE RUN FOLDERS + SBATCH FILES
#########################################
echo "Generating cactus job scripts..."

MASTER="$SCRIPTS/submit_all_cactus.sh"
echo "#!/bin/bash" > "$MASTER"

for setfile in "$SETS"/*.txt; do
    fname=$(basename "$setfile" .txt)
    rundir="$PANG/$fname"

    mkdir -p "$rundir"

    # build seqfile
    python3 "$SCRIPTS/build_seqfile.py" "$setfile" "$GENOMES" "$rundir/seqfile.txt"

    sb="$SCRIPTS/run_${fname}.sh"
    sed -e "s/CAC_NAME/$fname/g" -e "s#CAC_DIR#$rundir#g" \
        "$SCRIPTS/run_cactus_template.sh" \
        > "$sb"
    chmod +x "$sb"

    echo "sbatch $sb" >> "$MASTER"
done

chmod +x "$MASTER"

echo "✔ All cactus scripts generated"
echo "🔧 Submit all jobs with:  bash $MASTER"
echo "🎉 DONE"
