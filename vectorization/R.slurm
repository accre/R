#!/bin/bash
#SBATCH --mail-user=vunetid@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:10:00        # 10 minutes
#SBATCH --mem=500M
#SBATCH --output=R_job_slurm.out

setpkgs -a R_3.2.0
Rscript --no-save vectorize.R
# you can also use "R CMD BATCH vectorize.R", and 
# the output will go to a file named vectorize.Rout
