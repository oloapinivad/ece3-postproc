#!/bin/bash

# This is the config file for cca (CNR configuration), including all relevants information 
# to run the family of scripts of easy2cmor3

#----program folder definition ------- #

# Location of cmorization tool
SRCDIR=${HOME}/post

#source code of ece2cmor3
ECE2CMOR3DIR=${SRCDIR}/ece2cmor3/ece2cmor3

#Jon Seddon tables
TABDIR=${SRCDIR}/jon-seddon-tables/Tables

#Specify location of primavera-val
VALDIR=${SRCDIR}/primavera-val

#locaton of the easy2cmor3 (this folder)
EASYDIR=${ECE3_POSTPROC_TOPDIR}/easy2cmor3

#anaconda location
CONDADIR=${HOME}/opt/anaconda2/bin

#---------user configuration ---------#

# optional variable are $USERexp/$USER, $year
export ${USERexp:=$USER}
export IFSRESULTS0='/gpfs/scratch/userexternal/${USERexp}/ece3/${expname}/output/Output_${year}/IFS'
export NEMORESULTS0='/gpfs/scratch/userexternal/${USERexp}/ece3/${expname}/output/Output_${year}/NEMO'
export ECE3_POSTPROC_CMORDIR='/gpfs/scratch/userexternal/$USER/ece3/${expname}/cmorized/Year_${year}'

# define folder for logfile
LOGFILE=$CINECA_SCRATCH/log/cmorize
mkdir -p $LOGFILE || exit 1

# Temporary directories: cmor and linkdata
BASETMPDIR=$CINECA_SCRATCH/tmp_cmor
mkdir -p $BASETMPDIR || exit 1

#---PARALLELIZATION OPTIONS---#
NCORESATM=8 #parallelization is available for IFS
NCORESOCE=1
NCORESMERGE=32 #parallelization is available for merger
NCORESVALID=1
NCORESCORRECT=1
NCORESPREPARE=1 #parallelization is available but not very useful

#----machine dependent argument----#
ACCOUNT=$ECE3_POSTPROC_ACCOUNT 
SUBMIT="sbatch"
QUEUE_CMD="squeue -f"
PARTITION=gll_usr_prod

# as a function of the resolution change the memory and time requirements
if [[ $RESO == T511 ]] ; then
        MEMORY=50GB
        MEMORY2=110GB
        TLIMIT="03:59:00"
        DELTA=240
        TCHECK="07:59:00"
elif [[ $RESO == T255 ]] ; then
        MEMORY=20GB
        MEMORY2=${MEMORY}
        TLIMIT="00:59:00"
        DELTA=100
        TCHECK="01:59:00"
fi


#--------nco for merging---------------#
ncrcat="ncrcat -h"
ncatted="ncatted -hO"