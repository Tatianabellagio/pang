## VISOR + freqk pipeline (01–05)

This README describes how to run the parameterised benchmark pipeline (deletions **or** insertions) using VISOR + freqk.

### 0. Check and edit the config

Choose one config per run:

- Deletions: `scripts/config_sv_deletions.sh`
  - Paths: `WORK`, `REF`, `HAPS`, `READS`, `BEDS`, `VCF_DIR`, `RESULTS`
  - SV design: `SV_TYPE="DEL"`, `CHROM`, `SV_START_0`, `ANCHOR_POS`, `DEL_SIZES`
  - Pool‑seq: `FREQ`, `COVERAGE`, `ERROR_RATE`, `WT_CLONE` (step 02 creates `${HAPS}/_clone_WT` so 03 has a WT clone)
  - freqk: `K`, `FREQK`

- Insertions: `scripts/config_sv_insertions.sh`
  - Paths: `WORK`, `REF`, `HAPS`, `READS`, `BEDS`, `VCF_DIR`, `RESULTS`
  - SV design: `SV_TYPE="INS"`, `CHROM`, `SV_START_0`, `INS_SIZES`
  - Pool‑seq: `FREQ`, `COVERAGE`, `ERROR_RATE`, `WT_CLONE` (step 02 creates `${HAPS}/_clone_WT` for 03)
  - freqk: `K`, `FREQK`

Adjust these as needed (e.g. change `FREQ`, `COVERAGE`, `ERROR_RATE`, or add/remove sizes in `DEL_SIZES` / `INS_SIZES`).

In all commands below, pass the config explicitly as the second argument.

### 1. Make BEDs (01)

```bash
cd /home/tbellagio/scratch/pang/visor_freqk   # or your clone path
sbatch scripts/01_make_beds.sh scripts/config_sv_deletions.sh   # or config_sv_insertions.sh
sbatch scripts/01_make_beds.sh scripts/config_sv_insertions.sh   # or config_sv_insertions.sh

```

Depending on `SV_TYPE` in the config:

- `SV_TYPE="DEL"` → writes `hack_del_<SIZE>.bed` into `${BEDS}` for all sizes in `DEL_SIZES`.
- `SV_TYPE="INS"` → writes `hack_ins_<SIZE>.bed` into `${BEDS}` for all sizes in `INS_SIZES`.

### 2. Run VISOR HACk (02)

```bash
sbatch scripts/02_run_hack.sh scripts/config_sv_deletions.sh   # or config_sv_insertions.sh
sbatch scripts/02_run_hack.sh scripts/config_sv_insertions.sh
```

This uses the BEDs from step 01 and:

- **Creates the WT clone** at `${HAPS}/_clone_WT` (copy of the reference, no variants). Step 03 needs this for pool-seq (WT + variant clones).
- Writes variant haplotypes to:
  - Deletions: `${HAPS}/del_<SIZE>/HAP1` and `HAP2`
  - Insertions: `${HAPS}/ins_<SIZE>/HAP1` and `HAP2`

### 3. Simulate pool‑seq reads (03)

```bash
sbatch scripts/03_run_shorts.sh scripts/config_sv_deletions.sh   # or config_sv_insertions.sh
sbatch scripts/03_run_shorts.sh scripts/config_sv_insertions.sh   # or config_sv_insertions.sh

```

Reads are simulated with:

- Clone fractions from `FREQ`
- Coverage from `COVERAGE`
- Sequencing error from `ERROR_RATE`

Output FASTQs go to:

```text
${READS}/freq_<SIZE>_f<FREQ*100>_err<ERROR*100>/
  r1.fq
  r2.fq
```

For a new experiment (e.g. different `FREQ` or `ERROR_RATE`), edit the config and rerun step 03 to generate a new set of read folders with a different tag.

### 4. Build VCFs (04)

```bash
sbatch scripts/04_make_vcf.sh scripts/config_sv_deletions.sh   # or config_sv_insertions.sh
sbatch scripts/04_make_vcf.sh scripts/config_sv_insertions.sh
```

This creates VCFs for all SV sizes:

- **Deletions (DEL)**: sequence‑resolved VCFs using the validated anchor logic:

  ```text
  ${VCF_DIR}/del_<SIZE>.vcf.gz
  ${VCF_DIR}/del_<SIZE>.vcf.gz.tbi
  ```

- **Insertions (INS)**: sequence‑resolved insertion VCFs where:
-   - POS is the anchor base at the insertion site
-   - REF is the anchor base
-   - ALT is anchor + the same inserted sequence used in the HACk BED
-   - `SVLEN` is the insertion length from `INS_SIZES`:

  ```text
  ${VCF_DIR}/ins_<SIZE>.vcf.gz
  ${VCF_DIR}/ins_<SIZE>.vcf.gz.tbi
  ```

### 5. Run freqk end‑to‑end (05)

```bash
sbatch scripts/05_freqk.sh scripts/config_sv_deletions.sh   # or config_sv_insertions.sh
sbatch scripts/05_freqk.sh scripts/config_sv_insertions.sh
```

For each SV size, this runs:

1. `freqk index`
2. `freqk var-dedup`
3. `freqk ref-dedup`
4. `freqk count`
5. `freqk call`

All outputs for a given size are written under:

```text
${RESULTS}/cov<COVERAGE>_err<ERROR*100>/<SV_TYPE>/<SIZE>/f<FREQ*100>/k<K>/
```

with files:

- For deletions:
  - `del_<SIZE>.k<K>.freqk.index`
  - `del_<SIZE>.k<K>.freqk.var_index`
  - `del_<SIZE>.k<K>.freqk.ref_index`
  - `freq_<SIZE>_f<FREQ*100>_err<ERROR*100>.counts_by_allele.k<K>.tsv`
  - `freq_<SIZE>_f<FREQ*100>_err<ERROR*100>.raw_kmer_counts.k<K>.tsv`
  - `freq_<SIZE>_f<FREQ*100>_err<ERROR*100>.allele_frequencies.k<K>.tsv`

- For insertions:
  - `ins_<SIZE>.k<K>.freqk.index`
  - `ins_<SIZE>.k<K>.freqk.var_index`
  - `ins_<SIZE>.k<K>.freqk.ref_index`
  - `freq_<SIZE>_f<FREQ*100>_err<ERROR*100>.counts_by_allele.k<K>.tsv`
  - `freq_<SIZE>_f<FREQ*100>_err<ERROR*100>.raw_kmer_counts.k<K>.tsv`
  - `freq_<SIZE>_f<FREQ*100>_err<ERROR*100>.allele_frequencies.k<K>.tsv`

### Typical full run

After editing your chosen config (deletions or insertions):

```bash
sbatch scripts/01_make_beds.sh  <config>
sbatch scripts/02_run_hack.sh   <config>
sbatch scripts/03_run_shorts.sh <config>
sbatch scripts/04_make_vcf.sh   <config>
sbatch scripts/05_freqk.sh      <config>
```

You can rerun individual steps safely; outputs are either overwritten or written into new tagged folders (for different `FREQ` / `ERROR_RATE` combinations).

