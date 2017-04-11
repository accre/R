#!/bin/bash
#SBATCH --mail-user=vunetid@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --nodes=6
#SBATCH --tasks-per-node=1
#SBATCH --time=00:05:00
#SBATCH --mem=250M
#SBATCH --output=wdi-mpi.out

module load GCC OpenMPI R
R --version

srun --mpi=pmi2 Rscript wdi-mpi.r
