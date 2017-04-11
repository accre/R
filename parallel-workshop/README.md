Parallel Processing in R
========================

These are the notes for [Brenton Kenkel](http://bkenkel.com)'s workshop in the [Pizza and Programming Seminar](http://www.accre.vanderbilt.edu/?page_id=3243) series at Vanderbilt on April 12, 2017. These notes assume some familiarity with both the R statistical environment and the SLURM system that ACCRE uses for cluster job management, though I am happy to answer questions about either as they arise.

Why R?
------

In theory, R is a general-purpose scripting language like Python or Ruby. In practice, however, R is used for data analysis. What sets R apart from the crowd are its out-of-the-box data analysis features:

-   Native support for importing and managing tabular data.

-   Built-in statistical routines, including t-tests, ANOVA, linear regression, generalized linear models.

-   Extensive---and, if used thoughtfully, attractive---data visualization functions.

That's even before we get to the 10,000+ user-contributed packages available through [CRAN](https://cran.r-project.org/web/packages/), the official R package repository. R's main user base is statisticians, data scientists, academics, and other researchers who work with data. If you're interested in a new statistical or machine learning technique, there is often a user-friendly R package that implements it.

Why Parallelize?
----------------

Data analysis can be computationally intensive. You don't want to wait for your results any longer than you have to.

Most of us have access to multiple CPUs, if not through the ACCRE cluster then through mutlicore processors on our personal computers. By spreading a computationally intensive task across N CPUs, you can cut your computation time to approximately 1/N of what it would be otherwise. The trick is to identify which tasks can be distributed, or *parallelized*, in this way.

A task is a good candidate to parallelize if it consists of multiple parts that do not depend on each other's results. Here are a few examples from [a recent project of mine](http://doe-scores.com) (with Rob Carroll of Florida State) predicting military dispute outcomes that used parallelization extensively:

-   We had ten copies of the data, each with the missing values filled in differently---the result of multiple imputation. We ran the analysis in parallel across imputations, then averaged the results together at the end.

-   We used our model to generate "predictions" for every pair of countries for every year from 1816 to 2007 (about 1.5 million total). We split the data up by year, ran 192 separate prediction scripts in parallel, and collected the results together at the end.

-   We assessed the importance of each variable to our model by dropping it from the analysis and re-running. We ran the 18 drop-one-out analyses in parallel, then collected the results together at the end.

Not all computationally intensive tasks fit the bill. If step K depends on the results of step K-1, then these steps must be run in sequence. An example is Markov Chain Monte Carlo---you cannot run a chain in parallel, since the current iteration starts from the previous one.[1]

Job Arrays
----------

I will use a minimal data analysis example to illustrate the basic functionality for parallel processing in R. Time permitting, we will go through a more interesting substantive example at the end of the session.

The file `wdi-data.csv` is country-year data with the following three variables:

-   `female_lfp`: percentage of the country's female ages 15+ in the workforce

-   `fertility`: births per woman

-   `gdppc`: GDP per capita, in constant 2000 USD

Observations range from 1990 to 2014.

    country,year,female_lfp,fertility,gdppc
    Afghanistan,1990,15.5,7.466,NA
    Albania,1990,53.2000007629395,2.978,1879.65476406386
    Algeria,1990,9.89999961853027,4.726,3551.12851560399
    ...
    "Yemen, Rep.",2014,25.6000003814697,4.16,1103.75214271232
    Zambia,2014,73,5.353,1610.47554683502
    Zimbabwe,2014,83.5999984741211,3.923,829.693779248313

Suppose we want to examine the relationship between the fertility rate and women's labor force participation across countries in 1990, controlling for each country's overall wealth. We could use linear regression, via the `lm()` (as in "linear model") function in R.

``` r
wdi_data <- read.csv("wdi-data.csv")

fit_1990 <- lm(female_lfp ~ fertility + log(gdppc),
               data = wdi_data,
               subset = (year == 1990))

coef(fit_1990)
```

    ## (Intercept)   fertility  log(gdppc) 
    ##    107.6299     -2.1772     -6.1414

``` r
confint(fit_1990)
```

    ##               2.5 %     97.5 %
    ## (Intercept) 78.7369 136.522838
    ## fertility   -4.3119  -0.042557
    ## log(gdppc)  -8.8219  -3.460909

Notice the `response ~ predictor_1 + predictor_2 + ...` syntax, which is called a *formula* in R.

Now suppose we wanted to see how the strength of the relationship varies over time. Of course, since each regression takes 0.001 seconds, we could easily do that with a standard for loop. But if we had more data or were using more complex statistics, running each year in sequence might take a long time.

The script `wdi-by-year.r` takes a command line argument specifying the year (0 for 1990, 1 for 1991, etc.), runs the regression for that year, and appends the output to the CSV file `wdi-array-results.csv`:

``` r
### wdi-by-year.csv
###
### Run regression of female labor force participation on fertility and GDP per
### capita for year specified in command line argument

## Read command line argument (0 = 1990, 1 = 1991, etc)
args <- commandArgs(trailing = TRUE)
yr <- as.integer(args[1]) + 1990

## Load WDI data
wdi_data <- read.csv("wdi-data.csv")

## Run regression
fit <- lm(female_lfp ~ fertility + log(gdppc),
          data = wdi_data,
          subset = (year == yr))

## Gather output into one-row data frame
output <- data.frame(year = yr,
                     ci_low = confint(fit)["fertility", 1],
                     estimate = coef(fit)["fertility"],
                     ci_high = confint(fit)["fertility", 2])

## Store results in CSV file
out_file <- "wdi-array-results.csv"
write.table(output,
            file = out_file,
            sep = ",",
            append = TRUE,
            row.names = FALSE,
            col.names = FALSE)
```

For example, to add the results for the year 2000, we would run:

``` sh
Rscript wdi-by-year.r 10
```

What we want to do is run the script for every value from 0 to 24, simultaneously if possible. We can do this with a SLURM job array, as specified in the SLURM submission script `wdi-by-year.slurm`:

``` sh
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
```

When you submit this to ACCRE via `sbatch`, it creates 25 jobs---one for each element of the array. Depending on your fairshare, bursting limits, and other currently queued jobs, these jobs may run all at once, or a few at a time.

foreach + MPI
-------------

### Packages

To run the code in this section, you will need to have the following packages installed on ACCRE (or whatever machine you are using):

-   **foreach**
-   **doMPI**

To install these, use the command:

``` r
install.packages(c("doMC", "foreach"))
```

After installing the packages locally to your user directory, you may need to add the following line to your `.Rprofile` to ensure that R can find them:

``` r
.libPaths(c(.libPaths(),
            paste0("~/R/library/", as.character(getRversion()))))
```

### Syntax

If we weren't thinking about parallelization, the natural way to run our analysis for each year from 1990 to 2014 would be with a for loop.

``` r
years <- 1990:2014
output <- matrix(NA, nrow = length(years), ncol = 4)
colnames(output) <- c("year", "ci_low", "estimate", "ci_high")

for (i in 1:length(years)) {
    fit <- lm(female_lfp ~ fertility + log(gdppc),
              data = wdi_data,
              subset = (year == years[i]))

    output[i, "year"] <- years[i]
    output[i, "ci_low"] <- confint(fit)["fertility", 1]
    output[i, "estimate"] <- coef(fit)["fertility"]
    output[i, "ci_high"] <- confint(fit)["fertility", 2]
}

output
```

    ##       year   ci_low  estimate   ci_high
    ##  [1,] 1990 -4.31188 -2.177220 -0.042557
    ##  [2,] 1991 -4.05428 -1.911912  0.230459
    ##  [3,] 1992 -3.82055 -1.712898  0.394755
    ##  [4,] 1993 -3.51535 -1.420412  0.674530
    ##  [5,] 1994 -3.10880 -1.062890  0.983018
    ##  [6,] 1995 -2.76369 -0.835485  1.092723
    ##  [7,] 1996 -2.53801 -0.593730  1.350547
    ##  [8,] 1997 -2.05359 -0.144050  1.765490
    ##  [9,] 1998 -1.84743  0.065934  1.979294
    ## [10,] 1999 -1.74750  0.168229  2.083957
    ## [11,] 2000 -1.47908  0.431867  2.342814
    ## [12,] 2001 -1.25352  0.674334  2.602190
    ## [13,] 2002 -1.47278  0.516239  2.505258
    ## [14,] 2003 -1.29351  0.733664  2.760838
    ## [15,] 2004 -1.09882  0.960551  3.019921
    ## [16,] 2005 -1.00953  1.070617  3.150766
    ## [17,] 2006 -0.82626  1.307828  3.441915
    ## [18,] 2007 -0.71450  1.475530  3.665555
    ## [19,] 2008 -0.68652  1.557005  3.800530
    ## [20,] 2009 -0.76153  1.496826  3.755187
    ## [21,] 2010 -0.76436  1.524113  3.812582
    ## [22,] 2011 -0.77963  1.558610  3.896845
    ## [23,] 2012 -0.76111  1.601342  3.963790
    ## [24,] 2013 -0.79496  1.600247  3.995450
    ## [25,] 2014 -0.84140  1.605070  4.051545

Notice that the i'th step of the loop doesn't depend on the results of the i-1'th step, so this loop is a candidate for parallelization. The easiest way to parallelize the loop is to follow these steps:

1.  Rewrite the loop using the `foreach()` function provided by the **foreach** package.

2.  Register a "parallel backend" for `foreach()` through one of the "do" packages (**doMPI**, **doMC**, **doSNOW**, etc.).

Both of these steps are fairly easy. The syntax for `foreach()` is similar to that of a for loop, with two differences. First, `foreach()` is a function that returns a list, each of whose elements is the value calculated in the corresponding iteration of the loop. Therefore, unlike with for loops, there is no need to set up storage for the output in advance. Second, because of this, there cannot be interdependencies between steps of a `foreach()` loop.

`wdi-mpi.r` is a script that reimplements the loop above with `foreach()`, using MPI to parallelize:

``` r
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
```

The syntax in our SLURM submission script also changes when we use MPI:

``` sh
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
```

This script requests six nodes for computation. One of those nodes will be used to run the main script; when it reaches the `foreach()` loop, it will distribute tasks across the other five.

### Pros and Cons

Explicit parallelization via MPI (or another backend) has some pros and cons relative to the job array approach.

-   **Cleaner code.** With a job array, you need a separate script to collect your results and perform further analysis. With explicit parallelization, everything can be in one place.

-   **Requires less storage.** With a job array, you must save your intermediate results to a hard disk in order for the collection script to access them. This is burdensome if the intermediate results are large.

    By the same token, though, explicit parallelization may require access to more memory during the computation itself.

-   **Less flexible.** If you write a script to use MPI, it won't run on your local machine (unless you've set up MPI on your personal laptop). You can fix this by placing the cluster setup inside an if-else condition, at the expense of the "cleaner code" ideal.

-   **Less robust.** If you run an array of 100 jobs and 3 of them fail, you only need to re-run those 3. But if some of the jobs fail within a `foreach()` loop, unless you have been exceedingly careful in your coding, you will have to re-run the whole thing.

-   **More fairshare usage.** While the `foreach()` loop is running, the node running the main script is mostly idly waiting for results, eating up your fairshare. And as the loop reaches its end, the nodes that have finished also sit idle while waiting for the stragglers.

A Less Trivial Example
----------------------

For this example, we'll work with `adult-cleaned.csv`, a cleaned-up version of the "Adult" data hosted at [the UCI Machine Learning Repository](http://archive.ics.uci.edu/ml/datasets/Adult). This is census data, with the goal being to predict whether the respondent earns more or less than $50,000/year.

``` r
adult_data <- read.csv("adult-cleaned.csv")
head(adult_data)
```

    ##   income age        workclass education     marital_status  race    sex
    ## 1  <=50K  39        State-gov        13      Never-married White   Male
    ## 2  <=50K  50 Self-emp-not-inc        13 Married-civ-spouse White   Male
    ## 3  <=50K  38          Private         9           Divorced White   Male
    ## 4  <=50K  53          Private         7 Married-civ-spouse Black   Male
    ## 5  <=50K  28          Private        13 Married-civ-spouse Black Female
    ## 6  <=50K  37          Private        14 Married-civ-spouse White Female
    ##   capital_gain capital_loss hours_per_week
    ## 1         2174            0             40
    ## 2            0            0             13
    ## 3            0            0             40
    ## 4            0            0             40
    ## 5            0            0             40
    ## 6            0            0             40

We will use k-nearest neighbors, a simple but powerful predictive algorithm. An important problem is to choose the "tuning parameter" k, the number of nearest neighbors to use to make the prediction for each observation. A common approach is to choose k using 10-fold cross-validation. This is computationally intensive---it entails fitting the model 10 times for each candidate value of k.

The **caret** package has a function `train()` for user-friendly tuning and training of machine-learning models. A great feature of `train()` is that it uses `foreach()` and automatically detects whether we have registered a parallel backend, so as to parallelize the cross-validation process when possible.

The script `adult-mpi.r` compares the k-nearest neighbors training process with and without the benefit of parallelization.

``` r
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
```

And we have the associated SLURM submission script:

``` sh
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
```

Footnotes
---------

[1] Though, depending on the nature of your problem, you may be able to use parallelization to reduce computation time for each individual iteration.
