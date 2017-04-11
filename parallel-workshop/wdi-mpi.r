### wdi-mpi.r
###
### Run regression of female labor force participation on fertility and GDP per
### capita for every year 1990-2014, in parallel over MPI


## -----------------------------------------------------------------------------
## Cluster setup
## -----------------------------------------------------------------------------

## Required packages for parallel foreach loop over MPI
library("foreach")
library("doMPI")

## Set up error handling with Rmpi
##
## Without this code, the MPI session may fail to shut down properly in case an
## error occurs, and then the script won't terminate until it hits the walltime
options(error=quote(assign(".mpi.err", FALSE, env = .GlobalEnv)))

## Set up the cluster over MPI
##
## If started via `srun`, it should detect from the environment how many CPUs
## are available, so we don't need to tell it
cl <- startMPIcluster()

## Tell foreach() to parallelize on the MPI cluster
registerDoMPI(cl)


## -----------------------------------------------------------------------------
## Data analysis
## -----------------------------------------------------------------------------

## Load WDI data
wdi_data <- read.csv("wdi-data.csv")

## Run regression for each year
output <- foreach (yr = 1990:2014, .combine = "rbind") %dopar% {
    fit <- lm(female_lfp ~ fertility + log(gdppc),
              data = wdi_data,
              subset = (year == yr))

    ## Output for each iteration: vector
    c(year = yr,
      ci_low = confint(fit)["fertility", 1],
      estimate = coef(fit)["fertility"],
      ci_high = confint(fit)["fertility", 2])
}

print(output)


## -----------------------------------------------------------------------------
## Cluster shutdown
## -----------------------------------------------------------------------------

closeCluster(cl)
mpi.quit()
