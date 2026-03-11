# run from /home/tbellagio/scratch/pang/sv_panel
OUT=syri/merged
mkdir -p "$OUT/sv_vcfs"

for d in syri/results/*; do
  asm=$(basename "$d")
  vcf="$d/${asm}.tair10.syri.vcf"
  [[ -s "$vcf" ]] || continue

  # 1) rename sample column from "sample" to assembly name
  #    (SyRI VCF has 1 sample column called 'sample')
  mapfile="$OUT/${asm}.reheader.txt"
  echo -e "sample\t${asm}" > "$mapfile"

  # 2) filter to SV-like records
  #    - drop SYN + all *AL + SNP
  bcftools reheader -s "$mapfile" "$vcf" \
    | bcftools view -i 'ALT!~"^<SYN(AL)?>" && ALT!~"AL>$" && ALT!="<SNP>"' \
    | bcftools sort -Oz -o "$OUT/sv_vcfs/${asm}.syri.SVonly.vcf.gz"

  tabix -f -p vcf "$OUT/sv_vcfs/${asm}.syri.SVonly.vcf.gz"
done

