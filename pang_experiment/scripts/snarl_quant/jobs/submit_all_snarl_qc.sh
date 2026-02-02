#!/usr/bin/env bash
set -euo pipefail
sbatch "/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/scripts/snarl_quant/jobs/snarl_qc_set_02_rep1.sbatch"
sbatch "/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/scripts/snarl_quant/jobs/snarl_qc_set_02_rep2.sbatch"
sbatch "/carnegie/nobackup/scratch/tbellagio/pang/pang_experiment/scripts/snarl_quant/jobs/snarl_qc_set_02_rep3.sbatch"
