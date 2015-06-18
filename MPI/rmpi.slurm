#!/bin/bash
#SBATCH --mail-user=vunetid@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --nodes=2
#SBATCH --tasks-per-node=4
#SBATCH --time=00:10:00        # 10 minutes
#SBATCH --mem=500M
#SBATCH --output=R_job_slurm.out

setpkgs -a R_3.1.1
setpkgs -a openmpi_1.8.4

srun --mpi=pmi2 Rscript rmpi.R
