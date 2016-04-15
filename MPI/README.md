# Using R and MPI on ACCRE

## Installing Rmpi

You'll need to install the [Rmpi](http://cran.r-project.org/package=Rmpi) package from source and compile it against the version of OpenMPI you're using.  First, add R, the GCC compiler, and the OpenMPI or MPICH version of your choice to your PATH.

```bash
setpkgs -a R_3.1.1
setpkgs -a gcc_compiler

#Choose which version of MPI you desire. 
setpkgs -a openmpi_1.8.4
#setpkgs -a setpkgs -a mpich_3.1.4_gcc_ether
```

Next, download the Rmpi source code.

```bash
cd /tmp
wget http://cran.r-project.org/src/contrib/Rmpi_0.6-5.tar.gz
```

You'll need to supply the directory containing the OpenMPI `include/` and `lib/` directories when you install the package.  For the version of OpenMPI used here (1.8.4), the relevant directory is `/usr/local/openmpi/1.8.4/x86_64/gcc46`.

__For openmpi__
```bash
R CMD INSTALL Rmpi_0.6-5.tar.gz --configure-args=--with-mpi=/usr/local/openmpi/1.8.4/x86_64/gcc46
```

__For MPICH__
```bash
R CMD INSTALL Rmpi_0.6-5.tar.gz --configure-args="--with-mpi=/usr/local/mpich/3.1.4/nehalem/gcc49/ether/ --with-Rmpi-type=MPICH"
```

Using Rmpi is much easier, at least for embarrassingly parallel applications, with the [doMPI](http://cran.r-project.org/web/packages/doMPI/index.html) package.  To install this package from CRAN, just run the following in an R session:

```bash
wget https://cran.r-project.org/src/contrib/doMPI_0.2.1.tar.gz
R CMD INSTALL doMPI_0.2.1.tar.gz
```

When installing the Rmpi and doMPI packages, don't worry if you see the following warning message:

    PMI2 initialized but returned bad values for size and rank.
    This is symptomatic of either a failure to use the
    "--mpi=pmi2" flag in SLURM, or a borked PMI2 installation.
    If running under SLURM, try adding "-mpi=pmi2" to your
    srun command line. If that doesn't work, or if you are
    not running under SLURM, try removing or renaming the
    pmi2.h header file so PMI2 support will not automatically
    be built, reconfigure and build OMPI, and then try again
    with only PMI1 support enabled.
