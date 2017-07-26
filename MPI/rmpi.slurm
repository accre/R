#!/bin/bash
#SBATCH --mail-user=<my.email@vanderbilt.edu>
#SBATCH --mail-type=ALL
#SBATCH --nodes=2
#SBATCH --tasks-per-node=4
#SBATCH --time=00:10:00        # 10 minutes
#SBATCH --mem=500M
#SBATCH --output=R_job_slurm.out

module load GCC OpenMPI R

srun Rscript rmpi.R
