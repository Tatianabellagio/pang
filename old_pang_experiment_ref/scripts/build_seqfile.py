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
