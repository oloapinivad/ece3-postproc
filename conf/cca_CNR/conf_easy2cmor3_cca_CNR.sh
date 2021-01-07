#!/bin/bash

# This is the config file for cca (CNR configuration), including all relevants information 
# to run the family of scripts of easy2cmor3

#----program folder definition ------- #

# Location of cmorization tool
#SRCDIR=${PERM}/ecearth3/cmorization
#SRCDIR=/perm/ms/it/ccpd/ecearth3/cmorization
SRCDIR=/perm/ms/it/cc1f/ecearth3/cmorization/ # DynVar

#source code of ece2cmor3
ECE2CMOR3DIR=${SRCDIR}/ece2cmor3/ece2cmor3

#Jon Seddon tables
#TABDIR=${SRCDIR}/jon-seddon-tables-fix/Tables
#official tables
TABDIR=${ECE2CMOR3DIR}/resources/cmip6-cmor-tables/Tables

#Specify location of primavera-val
VALDIR=${SRCDIR}/primavera-val

#locaton of the easy2cmor3 (this folder)
EASYDIR=${ECE3_POSTPROC_TOPDIR}/easy2cmor3

#anaconda location
#CONDADIR=${PERM}/anaconda2/bin
#CONDADIR=/scratch/ms/it/ccpd/PRIMAVERA/anaconda2/bin
CONDADIR=/perm/ms/it/cc1f/miniconda2/bin

# storage information directory
INFODIR=${PERM}/ecearth3/infodir/cmorized
mkdir -p $INFODIR

#---------user configuration ---------#

# optional variable are $USERexp/$USER, $year
export ${USERexp:=$USER}
export RUNDIR0='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${expname}/run'
export IFSRESULTS0='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${expname}/output/Output_${year}/IFS'
export IFSRESULTS0_M1='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${expname}/output/Output_$(( year - 1 ))/IFS'
export NEMORESULTS0='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${expname}/output/Output_${year}/NEMO'
export LPJGRESULTS0='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${expname}/output/Output_${year}/LPJG'
export ECE3_POSTPROC_CMORDIR='${SCRATCH}/ece3/${expname}/cmorized/cmor_${year}'

# define folder for logfile
LOGFILE=$SCRATCH/log/cmorize
mkdir -p $LOGFILE || exit 1

# Temporary directories
BASETMPDIR=$SCRATCH/tmp_cmor
mkdir -p $BASETMPDIR || exit 1

#---PARALLELIZATION OPTIONS---#
NCORESATM=12 #parallelization is available for IFS
NCORESOCE=1
NCORESVEG=1
NCORESCORRECT=1
NCORESPREPARE=1
NCORESQA=108
NCORESNCTIME=18

#----machine dependent argument----#
ACCOUNT=$ECE3_POSTPROC_ACCOUNT 
SUBMIT="qsub"
QUEUE_CMD="qstat -f"
PARTITION=nf

# as a function of the resolution change the memory and time requirements
RESO=${RESO:-T255} 
if [[ $RESO == T511 ]] ; then
        MEMORY=50GB
        MEMORY2=60GB
        TLIMIT="03:59:00"
        TCHECK="07:59:00"
elif [[ $RESO == T255 ]] ; then
        MEMORY=50GB
        MEMORY2=${MEMORY}
        TLIMIT="11:59:00"
        TCHECK="23:59:00"
elif [[ $RESO == T799 ]] ; then
        MEMORY=80GB
        MEMORY2=${MEMORY}
        TLIMIT="05:59:00"
        TCHECK="11:59:00"
fi


#--------nco for merging---------------#
ncrcat="ncrcat -h"
ncatted="ncatted -hO"
