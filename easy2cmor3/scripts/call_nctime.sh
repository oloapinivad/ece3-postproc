#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (May 2019)
# Script to call nctime


# info for installation: does not work with python3
##conda create -n nctime python=2.7.16 anaconda
#source activate nctime
#pip install nctime
#pip install esgprep
#esgfetchini
#nctcck -c ~/ini ~/scratch/ece3/ch00/cmorized/Year_1850/
#nctxck -i ~/ini ~/scratch/ece3/ch00/cmorized/Year_1850/

set -e

#Will validate all years between year1 and year2 of experiment with name expname
expname=${expname:-chst}

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

#####################################################################################################

# activate conda
export PATH="$CONDADIR:$PATH"
NPROCS=2

# set path and log files
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
mkdir -p $INFODIR/${expname}
TREEDIR=$(echo $CMORDIR | rev | cut -f2- -d "/" | rev)

# start the environment
source activate nctime

# Check time coverage continuity
logfile1=$INFODIR/${expname}/EC-Earth_nctcck_${expname}.txt
echo "nctcck -i $HOME/ini --max-processes $NPROCS ${TREEDIR} ..."
nctcck -i $HOME/ini --max-processes $NPROCS ${TREEDIR} > $logfile1
echo "Done nctcck!"

# Check time axis correctness 
echo "nctxck -i $HOME/ini --max-processes $NPROCS ${TREEDIR} ..."
logfile2=$INFODIR/${expname}/EC-Earth_nctxck_${expname}.txt
nctxck -i $HOME/ini --max-processes $NPROCS ${TREEDIR} > $logfile2
echo "Done nctxck!"

#clean log
sed -i '/%/d' $logfile1
sed -i '/%/d' $logfile2


conda deactivate

