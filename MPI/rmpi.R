.libPaths("~/R/rlib-3.3.3") # need this to pick up our locally installed doMPI
library("Rmpi", quietly = TRUE)
library("doMPI", quietly = TRUE)

## Set up error handling with Rmpi
##
## Without this code, the MPI session may fail to shut down properly in case an
## error occurs, and then the script won't terminate until it hits the walltime
options(error=quote(assign(".mpi.err", FALSE, env = .GlobalEnv)))

## Set up the cluster via Rmpi
##
## If started via `srun`, it should detect from the environment how many CPUs
## are available, so we don't need to tell it
cl <- startMPIcluster()

## Tell `foreach` to parallelize on the MPI cluster
registerDoMPI(cl)

## Run loop in parallel over MPI
system.time(foreach (i = 1:16) %dopar% { Sys.sleep(10); mean(rnorm(1e4)) })

## Run sequentially as benchmark
system.time(foreach (i = 1:16) %do% { Sys.sleep(10); mean(rnorm(1e4)) })

## Shut down the cluster and exit the R session
closeCluster(cl)
mpi.quit()
