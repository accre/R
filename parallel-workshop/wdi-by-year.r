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
