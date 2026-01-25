#!/bin/bash
set -euo pipefail
set -x  # DEBUGGING so you see where it crashes

BASE_DIR="$HOME/scratch/pang/pang_experiment"
GENOME_DIR="$BASE_DIR/genomes"
SET_DIR="$BASE_DIR/sets"
PANG_DIR="$BASE_DIR/pangenomes"
SCRIPT_DIR="$BASE_DIR/scripts"

mkdir -p "$GENOME_DIR" "$SET_DIR" "$PANG_DIR" "$SCRIPT_DIR"

echo "✔ Created directory structure under $BASE_DIR"


###############################################
# 1. Copy genomes (skip empty files)
###############################################
SOURCE_GENOMES="$HOME/scratch/pang/pang_69/upload_genome"

echo "Copying genomes..."
for f in "$SOURCE_GENOMES"/*.fasta; do
    if [[ -s "$f" ]]; then
        cp "$f" "$GENOME_DIR/"
    else
        echo "⚠️ Skipping EMPTY genome: $(basename "$f")"
    fi
done
echo "✔ Genome copy done"


###############################################
# 2. Define overlap accessions
###############################################
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

ALL_GENOMES=($(ls "$GENOME_DIR"/*.fasta | xargs -n1 basename | sed 's/.fasta//'))

# Remove Col-0 from pool
ALL_NO_COL=($(printf "%s\n" "${ALL_GENOMES[@]}" | grep -v "^Col-0$"))

# Compute non-overlap
NON_OVERLAP=()
for g in "${ALL_NO_COL[@]}"; do
    if ! printf "%s\n" "${OVERLAP[@]}" | grep -q "^$g$"; then
        NON_OVERLAP+=("$g")
    fi
done

echo "Overlap count: ${#OVERLAP[@]}"
echo "Non-overlap count: ${#NON_OVERLAP[@]}"


###############################################
# 3. Define set sizes + reps
###############################################
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


###############################################
# 4. Generate subset files
###############################################
echo "Generating subset files..."

for setname in "${!SIZES[@]}"; do
    size=${SIZES[$setname]}
    reps=${REPS[$setname]}

    for rep in $(seq 1 $reps); do
        out="$SET_DIR/${setname}_rep${rep}.txt"

        if [[ "$setname" == "set_18" ]]; then
            # exact list + Col-0
            printf "%s\n" "Col-0" "${OVERLAP[@]}" > "$out"
            continue
        fi

        chosen=($(printf "%s\n" "${OVERLAP[@]}" | shuf -n $size))
        printf "%s\n" "Col-0" "${chosen[@]}" > "$out"
    done
done

# Set ALL
for rep in $(seq 1 ${REPS["set_all"]}); do
    printf "%s\n" "${ALL_GENOMES[@]}" > "$SET_DIR/set_all_rep${rep}.txt"
done

echo "✔ Subset generation complete"


###############################################
# 5. Create build_seqfile.py
###############################################
cat > "$SCRIPT_DIR/build_seqfile.py" <<'EOF'
#!/usr/bin/env python3
import sys, os

set_file = sys.argv[1]
genome_dir = sys.argv[2]
out_file = sys.argv[3]

with open(set_file) as f:
    accs = [l.strip() for l in f if l.strip()]

with open(out_file, "w") as out:
    for acc in accs:
        fasta = os.path.join(genome_dir, acc + ".fasta")
        if not os.path.isfile(fasta):
            raise FileNotFoundError(f"Missing FASTA: {fasta}")
        out.write(f"{acc}\t{fasta}\n")
EOF

chmod +x "$SCRIPT_DIR/build_seqfile.py"
echo "✔ build_seqfile.py created"


###############################################
# 6. Create cactus templates
###############################################
cat > "$SCRIPT_DIR/run_template.sh" <<'EOF'
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

rm -rf jobstore

cactus-pangenome \
    jobstore \
    seqfile.txt \
    --outDir output \
    --outName CAC_NAME \
    --reference Col-0 \
    --haplo --vcf --gfa --gbz --giraffe \
    --maxLen 10000 \
    --mgCores 8 --mapCores 8 --consCores 16 --indexCores 16

echo "DONE: CAC_NAME"
EOF

echo "✔ run_template.sh created"


###############################################
# 7. Make all run dirs + sbatch scripts
###############################################
MASTER="$SCRIPT_DIR/submit_all.sh"
echo "#!/bin/bash" > "$MASTER"

for file in "$SET_DIR"/*.txt; do
    name=$(basename "$file" .txt)
    run="$PANG_DIR/$name"
    mkdir -p "$run"

    python3 "$SCRIPT_DIR/build_seqfile.py" "$file" "$GENOME_DIR" "$run/seqfile.txt"

    sed -e "s/CAC_NAME/$name/g" -e "s#CAC_DIR#$run#g" \
        "$SCRIPT_DIR/run_template.sh" > "$run/run_cactus.sh"

    chmod +x "$run/run_cactus.sh"

    echo "sbatch $run/run_cactus.sh" >> "$MASTER"
done

chmod +x "$MASTER"
echo "✔ All sbatch scripts created"
echo "Run with:  bash $MASTER"
