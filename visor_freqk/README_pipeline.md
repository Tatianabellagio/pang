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

**Output paths and overlap:** All experiment parameters that affect data are encoded in paths so runs never overwrite each other. BEDs and haplotypes are reused when they already exist for the same config paths; reads and results always include coverage, error, and freq (and K in results). See "Pipeline output paths (no overlap)" below.

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

Output FASTQs go to (coverage and error are in the path so different experiments do not overlap):

```text
${READS}/<COV_LABEL>/freq_<SIZE>_f<FREQ%>_err<ERROR digits>/
  r1.fq
  r2.fq
```

Example: `data/reads/del/cov50/freq_1kb_f50_err0/`, `data/reads/del/cov20/freq_1kb_f50_err001/`.

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

### Pipeline output paths (no overlap)

Every config variable that changes the data is reflected in the output paths so different runs never overwrite each other.

| Step | Output location | What's in the path | Reuse? |
|------|-----------------|--------------------|--------|
| 01   | `${BEDS}/hack_del_<SIZE>.bed` or `hack_ins_<SIZE>.bed` | Config `BEDS`, `SV_TYPE`, size | Yes: if file exists, skip write |
| 02   | `${HAPS}/del_<SIZE>/HAP1,HAP2` or `ins_<SIZE>/...`, `${HAPS}/_clone_WT` | Config `HAPS`, `SV_TYPE`, size | Yes: if both `h1.fa` exist, skip HACk |
| 03   | `${READS}/<COV_LABEL>/freq_<SIZE>_f<FREQ%>_err<ERROR>/` | `READS`, **COVERAGE**, size, **FREQ**, **ERROR_RATE** | No: each run writes to its own dir |
| 04   | `${VCF_DIR}/del_<SIZE>.vcf.gz` or `ins_<SIZE>.vcf.gz` | Config `VCF_DIR`, `SV_TYPE`, size | Overwrites; VCF does not depend on cov/freq/error |
| 05   | `${RESULTS}/<COV>_<ERR>/<SV_TYPE>/<SIZE>/<FREQ>/k<K>/` | `RESULTS`, **COVERAGE**, **ERROR_RATE**, `SV_TYPE`, size, **FREQ**, **K** | No: each run writes to its own dir |

- **Design-only** (shared when same design): BEDs, haplotypes, VCFs. They depend on `SV_TYPE`, sizes, and positions; not on `COVERAGE`, `FREQ`, `ERROR_RATE`, or `K`. Steps 01 and 02 skip if outputs already exist.
- **Experiment-specific** (always separate): reads (03) and freqk results (05). Paths include coverage, error, freq, and (for 05) k, so different configs never share these folders.

If you use a different **design** (e.g. different `SV_START_0` or sizes), use a different top-level path in the config (e.g. `BEDS=${WORK}/data/beds/del_v2`) so BED/HAP/VCF stay separate.

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

