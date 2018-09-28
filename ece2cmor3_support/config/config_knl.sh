#!/bin/bash

# This is the config file for MARCONI, including all relevants information 
# to run the family of scripts of ece2cmor3_support

#----program folder definition ------- #

# Location of cmorization tool
SRCDIR=${WORK}/ecearth3/cmorization

#source code of ece2cmor3
ECE2CMOR3DIR=${SRCDIR}/ece2cmor3/ece2cmor3

#Jon Seddon tables
TABDIR=${SRCDIR}/jon-seddon-tables/Tables

#Specify location of primavera-val
VALDIR=${SRCDIR}/primavera-val

#locaton of the ece2cmor3_support (this folder)
SCRIPTDIR=${HOME}/ecearth3/ece3-postproc/ece2cmor3_support

#anaconda location
CONDADIR=${WORK}/opt/anaconda2/bin

#---------user configuration ---------#

#Specify root location of experiment output
ROOTPATH=$SCRATCH/ece3/${EXP}/cmorized

# define folder for logfile
LOGFILE=/marconi_scratch/userexternal/$USER/log/cmorize
mkdir -p $LOGFILE || exit 1

# Location of the experiment output (-u flag)
if [[ $USEREXP != $USER ]] ; then
   WORKDIR=/marconi_scratch/userexternal/$USEREXP/ece3/${EXP}/output
else
   WORKDIR=/marconi_scratch/userexternal/$USER/ece3/${EXP}/output
fi

# Temporary directories: cmor and linkdata
BASETMPDIR=$SCRATCH/tmp_cmor/${EXP}_${RANDOM}

#----machine dependent argument----#
ACCOUNT=${ECE3_POSTPROC_ACCOUNT}
SUBMIT="sbatch"
#PARTITION=bdw_usr_prod
PARTITION=knl_usr_prod
if [[ $RESO == T511 ]] ; then
        MEMORY=86000
        MEMORY2=${MEMORY}
        TLIMIT="19:59:00"
        DELTA=240
        TCHECK="23:59:00"
else
        MEMORY=20GB
        MEMORY2=${MEMORY}
        TLIMIT="00:59:00"
        DELTA=30
        TCHECK="01:59:00"
fi

#-----------------------#

cdozip="cdo -f nc4c -z zip"
ncrcat="ncrcat -h"
