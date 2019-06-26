#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (May 2019)
# Script to call QA-dkrz


# info for installation: prepare is installed in ece2cmor3
#conda create -n qa-dkrz -c conda-forge -c h-dh qa-dkrz
#qa-dkrz install --up --force CMIP6

set -e

#Will validate all years between year1 and year2 of experiment with name expname
expname=${expname:-chis}
do_force=true

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

#####################################################################################################

# activate conda
export PATH="$CONDADIR:$PATH"

# configurator
. ${EASYDIR}/config_and_create_metadata.sh $expname

# set path, options and log files for QA-DKRZ
year="*"
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
SELECT=CMIP6/${mip}/EC-Earth-Consortium/${model}/${exptype}/r${realization}i1p1f1
CHECK_MODE=TIME,DATA,CNSTY,CF,DRS,DRS_F,DRS_P
#CHECK_MODE=META,TIME,DATA
COREDIR=/lus/snx11062/scratch/ms/it/ccpd/tmp_cmor/QA/${expname}
QA_RESULTS=${COREDIR}/results
TMPDIR=${COREDIR}/linkdata
NUM_EXEC_THREADS=${NCORESQA:-1}



# replicating folder structure
rm -rf $TMPDIR
mkdir -p $TMPDIR
cp -nrs $(eval echo ${ECE3_POSTPROC_CMORDIR}/*) $TMPDIR

# cleaning old environment
if [[ ${do_force} == true ]] ; then
	rm -rf ${QA_RESULTS}
fi

# start the environment
source activate qa-dkrz

echo "Running QA-DKRZ"

qa-dkrz -P CMIP6 -E PROJECT_DATA=$TMPDIR -E SELECT=${SELECT} -E CHECK_MODE=${CHECK_MODE} -E QA_RESULTS=${QA_RESULTS} \
		-E NUM_EXEC_THREADS=${NUM_EXEC_THREADS} -m

echo  "Done!"

mkdir -p $INFODIR/${expname}
cp ${QA_RESULTS}/check_logs/Annotations/*.json $INFODIR/${expname}/
conda deactivate

