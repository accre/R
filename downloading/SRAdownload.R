# SRAdownload v1.0
# Author: Arunabh Singh, arunabh.singh@vanderbilt.edu
# This program was written for the Neuert Lab at Vanderbilt University through the VUSRP-ACCRE program.

# Purpose: Downloads SRA files from a remote ftp link and analyzes them through Babraham Bioinformatics' FastQC program.

# Conditions:
# Pre: The following is placed in the same directory as this code:
#       1) supplementary_programs, a folder containing  
#         a) fastq-dump 2.6.3: http://ncbi.github.io/sra-tools/fastq-dump.html
#         b) FastQC 0.11.2: http://www.bioinformatics.babraham.ac.uk/projects/download.html#fastqc
#       2) OPTIONAL: fastq, a folder containing all FASTQ input files to be processed; if not present, detail a ftp link below
# Post: The following directories are created:
#	1) sra: contains sra files
# 	2) fastq: contains fastq files
#	3) fastqc: contains FastQC reports

# User specifications
#####################################################################################################################################
# if applicable, edit path to the ftp for file download
# found through GEO, DDBJ, or EMBL, typically prefixed with "ftp://"
ftp <- ""

# edit path to "SRAdownload" folder
wd <- "/SRAdownload"

# Setup
#####################################################################################################################################
# sets directory
if (getwd() != wd) {
  setwd(wd)
}

# creates output folder
dir.create("fastqc")

# Download
#####################################################################################################################################
# select files to process
if (file.exists("fastq")) {
  files <- list.files("fastq", pattern = "fastq$")
  files <- substring(files, 1, nchar(files) - 6)
} else {
  system(paste0("wget ", ftp, " -r"))
  system("cd ftp* && find -type f -print0 | xargs -0 mv -t .. && cd ..")
  files <- list.files(pattern = "sra$")
  dir.create("sra")
  dir.create("fastq")
  file.rename(files, paste0("sra/", files))
  files <- substring(files, 1, nchar(files) - 4)
  unlink("ftp*", recursive = TRUE)
  
  for(i in 1:length(files)){
    print(paste0("Converting file ", i, " of ", length(files), " to FASTQ..."))
    system(paste0("supplementary_programs/fastq-dump.2.6.3 sra/", files[i], ".sra"))
    file.rename(paste0(files[i], ".fastq"), paste0("fastq/", files[i], ".fastq"))
  }
}

# FastQC Report
#####################################################################################################################################
for(i in 1:length(files)){
  print(paste0("Generating FastQC report for file ", i, " of ", length(files), "..."))
  system(paste0("export PATH=", wd, "/supplementary_programs/FastQC:$PATH && ", "fastqc fastq/", files[i], ".fastq"))
  file.remove(paste0("fastq/", files[i], "_fastqc.zip"))
  file.rename(paste0("fastq/", files[i], "_fastqc.html"), paste0("fastqc/", files[i], "_fastqc.html"))   # moves report
  }
}
