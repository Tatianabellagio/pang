#!/bin/bash
set -euo pipefail

#########################################
# 0. PATHS (NEW BASE)
#########################################
BASE="$HOME/scratch/pang/pang_experiment_test"
GENOMES="$BASE/genomes"
SETS="$BASE/sets"
PANG="$BASE/pangenomes"
SCRIPTS="$BASE/scripts"
REFDIR="$BASE/ref"

mkdir -p "$GENOMES" "$SETS" "$PANG" "$SCRIPTS" "$REFDIR"
echo "✔ Created directory structure under $BASE"

#########################################
# 0b. REFERENCE FASTA (TAIR10)
#########################################
REF_NAME="TAIR10"
REF_SRC="$HOME/scratch/pang/ref_gen/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"

if [[ ! -s "$REF_SRC" ]]; then
  echo "❌ Reference FASTA not found or empty: $REF_SRC" >&2
  exit 1
fi

# Keep a stable copy/link inside the experiment
ln -sf "$REF_SRC" "$REFDIR/${REF_NAME}.fasta"
# And symlink into genomes so seqfile generation works (expects *.fasta)
ln -sf "$REFDIR/${REF_NAME}.fasta" "$GENOMES/${REF_NAME}.fasta"

echo "✔ Reference set to: $REF_SRC"
echo "✔ Symlinked as: $GENOMES/${REF_NAME}.fasta"

#########################################
# 1. COPY GENOMES (skip empty)
#########################################
SRC="$HOME/scratch/pang/pang_69/upload_genome"
echo "Copying FASTA genomes (skipping empty files)..."

for f in "$SRC"/*.fasta; do
    if [[ -s "$f" ]]; then
        cp -f "$f" "$GENOMES/"
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
# All genome basenames present in GENOMES (including TAIR10)
mapfile -t ALL_GENOMES < <(ls "$GENOMES"/*.fasta | xargs -n1 basename | sed 's/\.fasta$//' | sort -u)

# Remove TAIR10 from selection pool (reference backbone)
mapfile -t ALL_NO_REF < <(printf "%s\n" "${ALL_GENOMES[@]}" | grep -v "^${REF_NAME}$")

# NON_OVERLAP = ALL_NO_REF minus OVERLAP
NON_OVERLAP=()
for g in "${ALL_NO_REF[@]}"; do
    if ! printf "%s\n" "${OVERLAP[@]}" | grep -qx "$g"; then
        NON_OVERLAP+=("$g")
    fi
done

echo "✔ Total genomes (incl ref): ${#ALL_GENOMES[@]}"
echo "✔ Total genomes (excl ref): ${#ALL_NO_REF[@]}"
echo "✔ Non-overlap list computed: ${#NON_OVERLAP[@]} genomes"

#########################################
# 4. DEFINE SET SIZES & REPS
# NOTE: "size" here means how many genomes chosen from OVERLAP for those sets,
# and TAIR10 is always added on top.
#########################################
declare -A SIZES=(
    [set_02]=2
    [set_05]=5
    [set_10]=10
    [set_15]=15
    [set_18]=18
    [set_50]=50
)

declare -A REPS=(
    [set_02]=3
    [set_05]=3
    [set_10]=3
    [set_15]=3
    [set_18]=1
    [set_50]=3
    [set_all]=1
)

#########################################
# 5. GENERATE SET FILES
#########################################
echo "Generating accession subset files..."

# helper: deduplicate while preserving order (in case anything repeats)
dedup_keep_order() { awk '!seen[$0]++'; }

for setname in "${!SIZES[@]}"; do
    size=${SIZES[$setname]}
    reps=${REPS[$setname]}

    for rep in $(seq 1 "$reps"); do
        outfile="$SETS/${setname}_rep${rep}.txt"

        if [[ "$setname" == "set_18" ]]; then
            # fixed set = TAIR10 + all 18 overlap
            {
                printf "%s\n" "$REF_NAME"
                printf "%s\n" "${OVERLAP[@]}"
            } | dedup_keep_order > "$outfile"
            continue
        fi

        if [[ "$setname" == "set_50" ]]; then
            # TAIR10 + all overlap + random non-overlap to reach 50 total
            # Total lines desired = 50
            # After TAIR10, we need 49 more. 18 are overlap => need 31 non-overlap.
            need_nonoverlap=$(( (size - 1) - ${#OVERLAP[@]} ))  # size is total lines here (50)
            if [[ "$need_nonoverlap" -lt 0 ]]; then
                echo "❌ set_50 size too small for overlap list" >&2
                exit 1
            fi
            if [[ "$need_nonoverlap" -gt "${#NON_OVERLAP[@]}" ]]; then
                echo "❌ Not enough NON_OVERLAP genomes: need $need_nonoverlap, have ${#NON_OVERLAP[@]}" >&2
                exit 1
            fi

            chosen_nonoverlap=($(printf "%s\n" "${NON_OVERLAP[@]}" | shuf -n "$need_nonoverlap"))

            {
                printf "%s\n" "$REF_NAME"
                printf "%s\n" "${OVERLAP[@]}"
                printf "%s\n" "${chosen_nonoverlap[@]}"
            } | dedup_keep_order > "$outfile"
            continue
        fi

        # random subset from overlap list (TAIR10 + N overlap)
        chosen=($(printf "%s\n" "${OVERLAP[@]}" | shuf -n "$size"))

        {
            printf "%s\n" "$REF_NAME"
            printf "%s\n" "${chosen[@]}"
        } | dedup_keep_order > "$outfile"
    done
done

# FULL set (1 rep): TAIR10 first + everything else (excluding TAIR10 to avoid duplication)
for rep in $(seq 1 "${REPS["set_all"]}"); do
    {
        printf "%s\n" "$REF_NAME"
        printf "%s\n" "${ALL_NO_REF[@]}"
    } | dedup_keep_order > "$SETS/set_all_rep${rep}.txt"
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
    --reference TAIR10 \
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
