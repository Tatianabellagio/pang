PILOT=/home/tbellagio/scratch/pang/test_freqk/pilot_site4
SRCROOT=/home/tbellagio/scratch/pang/grenenet_reads/grenenet-phase1
NAMES=/home/tbellagio/scratch/pang/grenenet_reads/site4_fastqs_names.txt

cd $PILOT

# Extract fastq basenames (skip header ",0")
awk -F',' 'NR>1{print $2}' "$NAMES" | sed '/^$/d' > site4_fastq_basenames.txt

# Find each file and symlink into reads/
: > site4_reads.manifest.tsv
i=0
while read -r bn; do
  p=$(find "$SRCROOT" -type f -name "$bn" 2>/dev/null | head -n 1)
  if [[ -z "$p" ]]; then
    echo -e "MISSING\t$bn\t-" >> site4_reads.manifest.tsv
    continue
  fi
  # make a stable local name
  tag=$(printf "site4_%03d" "$i")
  ln -sf "$p" "reads/${tag}.fq.gz"
  echo -e "OK\t$tag\t$p" >> site4_reads.manifest.tsv
  i=$((i+1))
done < site4_fastq_basenames.txt

echo "Manifest:"
column -t site4_reads.manifest.tsv | head
echo
echo "Count OK vs missing:"
awk '{c[$1]++} END{for(k in c) print k,c[k]}' site4_reads.manifest.tsv
