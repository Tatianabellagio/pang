Downloaded the ref fasta from ensemble 
https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-62/fasta/arabidopsis_thaliana/dna/
got the toplevel

wget ftp://ftp.ensemblgenomes.org/pub/plants/release-57/fasta/arabidopsis_thaliana/dna/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz

becasue tair was not working 

https://www.arabidopsis.org/download/list?dir=Genes%2FTAIR10_genome_release%2FTAIR10_chromosome_files


bwa-mem2 index Arabidopsis_thaliana.TAIR10.dna.toplevel.fa
bwa-mem2 index Col-0.fasta





vg filter \
  --tsv-out "name;identity;mapping_quality;is_perfect;length;softclip_start;softclip_end" \
  S1.gam \
  > S1.identity_full.tsv