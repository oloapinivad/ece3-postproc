#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Adapted from Pierre-Antoine Bretonniere and Jon Seddon
# Script to call PrePARE to validate NetCDF successfully.

set -e

#Will validate all years between year1 and year2 of experiment with name expname
expname=${expname:-chis}
year=${year:-1850}

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

#####################################################################################################

# activate conda
export PATH="$CONDADIR:$PATH"

# set path and log files
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
cd $CMORDIR
mkdir -p $INFODIR/${expname}
LOGFILE=$INFODIR/${expname}/PrePARE_${expname}_${year}.txt
rm -f $LOGFILE

# start the environment
# cmor nightly built environment must be installed in conda via: conda create -n cmor-nightly -c pcmdi/label/nightly -c conda-forge cmor
source activate cmor-nightly

PrePARE --table-path $TABDIR --max-processes=$NCORESPREPARE $CMORDIR  >> $LOGFILE
sed -i '/%/d' $logfile1

nfile=$(find $CMORDIR -name "*.nc" | wc -l )

conda deactivate

