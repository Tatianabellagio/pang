#!/usr/bin/env bash
set -euo pipefail

ROOT="20260209_Exposito-Alonso"

asm_dir="$ROOT/01_assemblies"
rm_dir="$ROOT/02_annotation_RepeatMasker"
trash_dir="$ROOT/03_annotation_TRASH_v2"
t10_dir="$ROOT/12_annotation_liftoff_TAIR10_sc0.90"
t12_dir="$ROOT/12_annotation_liftoff_TAIR12_sc0.90"
hel_dir="$ROOT/13_annotation_helixer_v0.3.5"

echo "== Basic presence =="
for d in "$asm_dir" "$rm_dir" "$trash_dir" "$t10_dir" "$t12_dir" "$hel_dir"; do
  [[ -d "$d" ]] || { echo "MISSING DIR: $d"; exit 1; }
done
echo "OK: all expected directories present"
echo

echo "== Count assemblies (by .fa.gz) =="
n_asm=$(ls -1 "$asm_dir"/*.scaffolds_contigs.fa.gz 2>/dev/null | wc -l | tr -d ' ')
echo "Assemblies (.fa.gz): $n_asm"
echo

echo "== Compare ID sets across folders =="
# derive canonical ID list from assemblies
ls -1 "$asm_dir"/*.scaffolds_contigs.fa.gz \
  | sed -E 's#.*/([0-9]+)\.scaffolds_contigs\.fa\.gz#\1#' \
  | sort -u > ids.asm.txt

for label in RepeatMasker TRASH TAIR10 TAIR12 HELIXER; do
  case "$label" in
    RepeatMasker)
      ls -1 "$rm_dir"/*.Repeats_merged.gff 2>/dev/null \
        | sed -E 's#.*/([0-9]+)\.Repeats_merged\.gff#\1#' | sort -u > ids.${label}.txt ;;
    TRASH)
      ls -1 "$trash_dir"/*.scaffolds_contigs.reformatted.gff 2>/dev/null \
        | sed -E 's#.*/([0-9]+)\.scaffolds_contigs\.reformatted\.gff#\1#' | sort -u > ids.${label}.txt ;;
    TAIR10)
      ls -1 "$t10_dir"/*.TAIR10.genes.gff 2>/dev/null \
        | sed -E 's#.*/([0-9]+)\.TAIR10\.genes\.gff#\1#' | sort -u > ids.${label}.txt ;;
    TAIR12)
      ls -1 "$t12_dir"/*.TAIR12.genes.gff 2>/dev/null \
        | sed -E 's#.*/([0-9]+)\.TAIR12\.genes\.gff#\1#' | sort -u > ids.${label}.txt ;;
    HELIXER)
      ls -1 "$hel_dir"/*_helixer.gff3.gz 2>/dev/null \
        | sed -E 's#.*/([0-9]+)_helixer\.gff3\.gz#\1#' | sort -u > ids.${label}.txt ;;
  esac

  echo "-- $label --"
  echo "  n(ids): $(wc -l < ids.${label}.txt | tr -d ' ')"
  only_in_asm=$(comm -23 ids.asm.txt ids.${label}.txt | wc -l | tr -d ' ')
  only_in_lbl=$(comm -13 ids.asm.txt ids.${label}.txt | wc -l | tr -d ' ')
  echo "  missing from $label (present in assemblies): $only_in_asm"
  echo "  extra in $label (not in assemblies):        $only_in_lbl"
done
echo

echo "== FASTA header check: presence of Chr1–Chr5 =="
# output: file, missing list
out_chr="missing_chr.tsv"
echo -e "id\tmissing_chr" > "$out_chr"

for f in "$asm_dir"/*.scaffolds_contigs.fa.gz; do
  id=$(basename "$f" | cut -d. -f1)
  miss=()
  for c in Chr1 Chr2 Chr3 Chr4 Chr5; do
    if ! zgrep -qE "^>${c}(\s|$)" "$f"; then
      miss+=("$c")
    fi
  done
  if ((${#miss[@]})); then
    echo -e "${id}\t${miss[*]}" >> "$out_chr"
  fi
done

n_missing=$(tail -n +2 "$out_chr" | wc -l | tr -d ' ')
echo "Assemblies missing any of Chr1-5: $n_missing"
if [[ "$n_missing" -gt 0 ]]; then
  echo "See: $out_chr (showing first 20)"
  head -n 21 "$out_chr"
fi
echo

echo "== FASTA .fai consistency spot-check (names match) =="
# check first 20 for speed; adjust if you want all
out_fai="fai_mismatch.tsv"
echo -e "id\tn_fai\tn_fasta_headers\tstatus" > "$out_fai"

i=0
for f in "$asm_dir"/*.scaffolds_contigs.fa.gz; do
  ((i++)) || true
  [[ "$i" -le 20 ]] || break
  id=$(basename "$f" | cut -d. -f1)
  fai="$asm_dir/${id}.scaffolds_contigs.fa.fai"
  if [[ ! -s "$fai" ]]; then
    echo -e "${id}\tNA\tNA\tMISSING_FAI" >> "$out_fai"
    continue
  fi
  n_fai=$(wc -l < "$fai" | tr -d ' ')
  n_hdr=$(zgrep -c '^>' "$f" || true)
  status="OK"
  [[ "$n_fai" -eq "$n_hdr" ]] || status="COUNT_MISMATCH"
  echo -e "${id}\t${n_fai}\t${n_hdr}\t${status}" >> "$out_fai"
done
echo "Wrote: $out_fai (first 20 assemblies)"
echo "Any mismatches?"
awk -F'\t' 'NR==1{next} $4!="OK"{print}' "$out_fai" | head
echo

echo "== Annotation sanity: non-empty + 9-col format (quick sample) =="
# sample 5 files per folder for speed
check_gff () {
  local label="$1" dir="$2" pattern="$3" gz="$4"
  echo "-- $label --"
  mapfile -t files < <(ls -1 "$dir"/$pattern 2>/dev/null | head -n 5)
  for f in "${files[@]}"; do
    if [[ "$gz" == "1" ]]; then
      n_noncomment=$(zcat "$f" | awk '$0 !~ /^#/ && $0 ~ /\S/ {n++} END{print n+0}')
      n_bad=$(zcat "$f" | awk '$0 !~ /^#/ && $0 ~ /\S/ { if (NF<9) b++ } END{print b+0}')
    else
      n_noncomment=$(awk '$0 !~ /^#/ && $0 ~ /\S/ {n++} END{print n+0}' "$f")
      n_bad=$(awk '$0 !~ /^#/ && $0 ~ /\S/ { if (NF<9) b++ } END{print b+0}' "$f")
    fi
    echo "$(basename "$f")  noncomment=${n_noncomment}  bad9col=${n_bad}"
  done
}

check_gff "RepeatMasker" "$rm_dir" "*.gff" 0
check_gff "TRASH" "$trash_dir" "*.gff" 0
check_gff "TAIR10 liftoff" "$t10_dir" "*.gff" 0
check_gff "TAIR12 liftoff" "$t12_dir" "*.gff" 0
check_gff "Helixer" "$hel_dir" "*.gff3.gz" 1

echo
echo "All checks finished."
