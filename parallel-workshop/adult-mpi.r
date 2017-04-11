### adult-mpi.r
###
### Use k-nearest neighbors to develop a predictive model of who earns at least
### $50K/year in mid-1990s Census data


## -----------------------------------------------------------------------------
## Cluster setup
## -----------------------------------------------------------------------------

library("foreach")
library("doMPI")

options(error=quote(assign(".mpi.err", FALSE, env = .GlobalEnv)))

cl <- startMPIcluster()
registerDoMPI(cl)


## -----------------------------------------------------------------------------
## Data analysis
## -----------------------------------------------------------------------------

library("caret")

adult_data <- read.csv("adult-cleaned.csv")

## Baseline: run cross-validation sequentially
fit_seq <- train(income ~ age + race + sex + education + hours_per_week,
                 data = adult_data,
                 method = "knn",
                 preProcess = c("center", "scale"),
                 trControl = trainControl(
                     method = "cv",
                     number = 10,
                     allowParallel = FALSE
                 ),
                 tuneLength = 5)

print(fit_seq)
print(fit_seq$times)

## Re-run in parallel
fit_par <- train(income ~ age + race + sex + education + hours_per_week,
                 data = adult_data,
                 method = "knn",
                 preProcess = c("center", "scale"),
                 trControl = trainControl(
                     method = "cv",
                     number = 10,
                     allowParallel = TRUE
                 ),
                 tuneLength = 5)

print(fit_par)
print(fit_par$times)


## -----------------------------------------------------------------------------
## Cluster shutdown
## -----------------------------------------------------------------------------

closeCluster(cl)
mpi.quit()
