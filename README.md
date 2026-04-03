# pang

Exploration of pangenome construction and read alignment for *Arabidopsis thaliana* using [Cactus](https://github.com/ComparativeGenomicsToolkit/cactus) and [vg](https://github.com/vgteam/vg). The project builds a pangenome graph from 69 *A. thaliana* assemblies and benchmarks short-read alignment to the graph using vg Giraffe, with the goal of improving variant calling for pool-seq GrENE-Net data.

---

## Overview

1. **Pangenome construction** — 69 *A. thaliana* genome assemblies are used to build a pangenome graph with `cactus-pangenome` (Col-0 as reference), producing GBZ, GFA, and VCF outputs.
2. **Read alignment** — GrENE-Net short reads are aligned to the pangenome graph using `vg giraffe`.
3. **Variant calling exploration** — `vg pack` computes read support (coverage) per node; `vg snarls` identifies bubble structures for downstream variant calling.

---

## Repository structure

```
run_cactus/                    # Cactus pangenome build scripts
run_cactus.sh                  # Main cactus-pangenome submission script
setup_pangenome_experiment.sh  # Environment and index setup
run_vg_giraffe/                # vg Giraffe alignment scripts
data_expl.ipynb                # Data exploration notebook
reads_expl.ipynb               # Read alignment exploration
snarl_explorer.ipynb           # Snarl/bubble structure exploration
sum_pang_expl.ipynb            # Summary of pangenome exploration
sv_panel/                      # SV panel analyses
```

---

## Key steps

### Build pangenome (Cactus)

```bash
cactus-pangenome \
    jobstore \
    seqfile.txt \
    --outDir output_pangraph \
    --outName arabidopsis69 \
    --reference Col-0 \
    --vcf --gbz --gfa --giraffe \
    --mgCores 32 --mapCores 8 --consCores 32 --indexCores 32 \
    --maxLen 10000 --haplo
```

`seqfile.txt` format: `sample_name\tpath/to/assembly.fasta` (one per line).

### Align reads with vg Giraffe

```bash
vg giraffe \
    -Z arabidopsis69filtered.d2.gbz \
    -d arabidopsis69filtered.d2.dist \
    -m arabidopsis69filtered.d2.shortread.withzip.min \
    -z arabidopsis69filtered.d2.shortread.zipcodes \
    -f reads_R1.fq.gz -f reads_R2.fq.gz \
    -t 32 \
    > output.gam
```

### Compute coverage and call variants

```bash
# Alignment stats
vg stats -a output.gam > gam_stats.txt

# Per-node coverage
vg pack -x graph.gbz -g output.gam -o output.pack -t 8

# Snarls (bubble structures)
vg snarls -t 16 graph.gbz > graph.snarls

# Traversals (all candidate haplotypes, no genotyping)
vg call -T graph.gbz -k output.pack -r graph.snarls > traversals.gaf
```

---

## Tools & dependencies

- [Cactus](https://github.com/ComparativeGenomicsToolkit/cactus) — pangenome graph construction
- [vg](https://github.com/vgteam/vg) — variation graph toolkit (Giraffe, pack, snarls, call)
- Python 3, Jupyter, SLURM

---

## Data

Assemblies sourced from the [Max Planck Institute EDMOND repository](https://edmond.mpg.de/dataset.xhtml?persistentId=doi:10.17617/3.AEOJBL) (69 *A. thaliana* accessions). Reads from the GrENE-Net phase 1 dataset.
