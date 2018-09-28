#!/bin/bash

# This is the config file for MARCONI, including all relevants information 
# to run the family of scripts of ece2cmor3_support

#----program folder definition ------- #

# Location of cmorization tool
SRCDIR=${PERM}/ecearth3/cmorization

#source code of ece2cmor3
ECE2CMOR3DIR=${SRCDIR}/ece2cmor3/ece2cmor3

#Jon Seddon tables
TABDIR=${SRCDIR}/jon-seddon-tables/Tables

#Specify location of primavera-val
VALDIR=${SRCDIR}/primavera-val

#locaton of the easy2cmor3 (this folder)
EASYDIR=${ECE3_POSTPROC_TOPDIR}/easy2cmor3

#anaconda location
CONDADIR=${SCRATCH}/PRIMAVERA/anaconda2/bin

#---------user configuration ---------#

# optional variable are $USERexp/$USER, $LEGNB, $year
export ${USERexp:=$USER}
export IFSRESULTS0='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${EXPID}/output/Output_${year}/IFS'
export NEMORESULTS0='/lus/snx11062/scratch/ms/it/${USERexp}/ece3/${EXPID}/output/Output_${year}/NEMO'
export ECE3_POSTPROC_CMORDIR='${SCRATCH}/ece3/${EXPID}/cmorized/Year_${year}'

# superflous but needed to integrate in ece3-postproc
export ECE3_POSTPROC_POSTDIR='${SCRATCH}/ece3/${EXPID}/post/Post_${year}'
export yref=1950
export months_per_leg=12 

# define folder for logfile
LOGFILE=$SCRATCH/log/cmorize
mkdir -p $LOGFILE || exit 1

# Temporary directories: cmor and linkdata
BASETMPDIR=$SCRATCH/tmp_cmor

#----machine dependent argument----#
ACCOUNT=$ECE3_POSTPROC_ACCOUNT 
SUBMIT="qsub"
PARTITION=nf
if [[ $RESO == T511 ]] ; then
        MEMORY=50GB
        MEMORY2=100GB
        TLIMIT="03:59:00"
        DELTA=240
        TCHECK="07:59:00"
else
        MEMORY=20GB
        MEMORY2=${MEMORY}
        TLIMIT="00:59:00"
        DELTA=100
        TCHECK="01:59:00"
fi

#-----------------------#

cdozip="cdo -f nc4c -z zip"
ncrcat="ncrcat -h"
