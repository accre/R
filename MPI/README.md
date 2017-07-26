# Using R and MPI on ACCRE

## Installing Rmpi

You'll need to install the [Rmpi](http://cran.r-project.org/package=Rmpi) package to run this example.  First, add R, the GCC compiler, and the OpenMPI to your PATH:

```bash
module load GCC OpenMPI R
```

You're now ready to install Rmpi. If you don't already have one, create a directory for local installations of R packages:

```bash
mkdir -p ~/R/rlib-3.3.3
```

Now instll Rmpi:

```bash
R
.
.
.
> .libPaths("~/R/rlib-3.3.3")
> install.packages("Rmpi")
.
.
.
```

You will be asked to select a CRAN mirror. Most should be fine, generally selecting one that is geographically close to your current location is a good rule of thumb.
