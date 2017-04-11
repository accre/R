#!/bin/bash
#SBATCH --mail-user=vunetid@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --nodes=6
#SBATCH --tasks-per-node=1
#SBATCH --time=00:15:00
#SBATCH --mem=2G
#SBATCH --output=adult-mpi.out

module load GCC OpenMPI R
R --version

srun --mpi=pmi2 Rscript adult-mpi.r
