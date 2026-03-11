#!/bin/bash
#SBATCH --job-name=visor_hack
#SBATCH --output=logs/02_run_hack_%j.out
#SBATCH --error=logs/02_run_hack_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
# =============================================================================
# 02_run_hack.sh
# Purpose: Run VISOR HACk to inject homozygous SVs into Chr1
#          (deletions or insertions, depending on config SV_TYPE)
#          Parameters come from a config file (default: config_sv_deletions.sh)
# Output (DEL): ${HAPS}/del_<size>/HAP1/ and HAP2/
# Output (INS): ${HAPS}/ins_<size>/HAP1/ and HAP2/
# =============================================================================
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
source "$(mamba info --base)/etc/profile.d/conda.sh" && conda activate pang

CONFIG_FILE=${1:-"$(dirname "$0")/config_sv_deletions.sh"}
source "${CONFIG_FILE}"

mkdir -p logs "${HAPS}"

# -----------------------------------------------------------------------------
# Create WT clone (reference with no variants) for SHORtS. SHORtS expects each
# sample dir to contain *.fa; 03_run_shorts uses WT_CLONE as the second clone.
# Without this, SHORtS would fail (or use wrong/missing path).
# -----------------------------------------------------------------------------
WT_CLONE_DIR="${WT_CLONE}"
mkdir -p "${WT_CLONE_DIR}"
REF_FA="${WT_CLONE_DIR}/$(basename "${REF}")"
if [[ ! -s "${REF_FA}" ]]; then
  echo "[$(date)] Creating WT clone at ${WT_CLONE_DIR} (copy of reference)"
  cp "${REF}" "${REF_FA}"
  cp "${REF}.fai" "${WT_CLONE_DIR}/$(basename "${REF}.fai")"
  echo "[$(date)] WT clone ready: ${REF_FA}"
else
  echo "[$(date)] WT clone already exists: ${REF_FA}"
fi

case "${SV_TYPE}" in
  "DEL")
    for SIZE in "${!DEL_SIZES[@]}"; do
        LEN=${DEL_SIZES[$SIZE]}
        BED=${BEDS}/hack_del_${SIZE}.bed
        HAP1_OUT=${HAPS}/del_${SIZE}/HAP1
        HAP2_OUT=${HAPS}/del_${SIZE}/HAP2

        # If haplotypes already exist (both HAP1 and HAP2 have h1.fa), skip recomputation
        if [[ -s "${HAP1_OUT}/h1.fa" && -s "${HAP2_OUT}/h1.fa" ]]; then
          echo "[$(date)] Reusing existing haplotypes for DEL ${SIZE} in ${HAP1_OUT}, ${HAP2_OUT}"
        else
          rm -rf "${HAP1_OUT}" "${HAP2_OUT}"
          mkdir -p "${HAP1_OUT}" "${HAP2_OUT}"

          echo "[$(date)] Running VISOR HACk (DEL) for size: ${SIZE} (len=${LEN})"

          VISOR HACk -g "${REF}" -b "${BED}" -o "${HAP1_OUT}"
          VISOR HACk -g "${REF}" -b "${BED}" -o "${HAP2_OUT}"

          echo "[$(date)] Done: del_${SIZE}"
        fi
    done
    echo "[$(date)] All deletions processed. Haplotypes in ${HAPS}"
    ;;
  "INS")
    for SIZE in "${!INS_SIZES[@]}"; do
        LEN=${INS_SIZES[$SIZE]}
        BED=${BEDS}/hack_ins_${SIZE}.bed
        HAP1_OUT=${HAPS}/ins_${SIZE}/HAP1
        HAP2_OUT=${HAPS}/ins_${SIZE}/HAP2

        if [[ -s "${HAP1_OUT}/h1.fa" && -s "${HAP2_OUT}/h1.fa" ]]; then
          echo "[$(date)] Reusing existing haplotypes for INS ${SIZE} in ${HAP1_OUT}, ${HAP2_OUT}"
        else
          rm -rf "${HAP1_OUT}" "${HAP2_OUT}"
          mkdir -p "${HAP1_OUT}" "${HAP2_OUT}"

          echo "[$(date)] Running VISOR HACk (INS) for size: ${SIZE} (len=${LEN})"

          VISOR HACk -g "${REF}" -b "${BED}" -o "${HAP1_OUT}"
          VISOR HACk -g "${REF}" -b "${BED}" -o "${HAP2_OUT}"

          echo "[$(date)] Done: ins_${SIZE}"
        fi
    done
    echo "[$(date)] All insertions processed. Haplotypes in ${HAPS}"
    ;;
  *)
    echo "02_run_hack.sh: unsupported SV_TYPE=${SV_TYPE} (expected DEL or INS)" >&2
    exit 1
    ;;
esac