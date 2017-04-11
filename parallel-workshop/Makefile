all : README.md

README.md : workshop-notes.Rmd wdi-by-year.slurm wdi-data.csv
	gpp -x workshop-notes.Rmd -o README.Rmd
	Rscript -e "rmarkdown::render('README.Rmd')"

.PHONY : clean
clean :
	rm -f *.out
	rm -f wdi-array-results.csv
