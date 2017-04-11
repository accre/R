#!/bin/bash
#SBATCH --mail-user=vunetid@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --ntasks=1
#SBATCH --time=00:05:00
#SBATCH --mem=250M
#SBATCH --array=0-24
#SBATCH --output=wdi-by-year-%a.out

module load GCC OpenMPI R
R --version

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID

Rscript wdi-by-year.r $SLURM_ARRAY_TASK_ID
