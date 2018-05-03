#!/bin/bash

###############################################################################
#
# Filter and CMORize one year of EC-Earth output: uses CMIP6 tables only.
# This script submits 12+1 jobs, each filtering/cmorizing one month of data.
#
#
# Note that for NEMO processing, all files in the output folder will be
# processed irrespective of the MON variable, so this is only useful for IFS.
#
# ATM=1 means process IFS data.
# OCE=1 means process NEMO data (default is 0).
#
# Other choices of output (output/tmp dirs etc.) are set in cmor_mon_filter.sh.
#
# Paolo Davini (Apr 2018) - based on a script by Gijs van Oord and Kristian Strommen
#
################################################################################

set -ue

#---input argument----#
EXP=qctr
YEAR=1950
ATM=1
OCE=0
USEREXP=imavilia  #extra by P. davini: allows analysis of experiment owned by different user

#----machine dependent argument----#
NCORES=8
ACCOUNT=IscrB_DIXIT
MEMORY=50GB
TLIMIT="03:59:00"
SUBMIT="sbatch"
PARTITION=bdw_usr_prod

#-----------------------#

# define folder for logfile
LOGFILE=/marconi_scratch/userexternal/$USER/log/cmorize
mkdir -p $LOGFILE || exit 1

# A bit of log...
echo "========================================================="
echo "Processing and CMORizing year $YEAR of experiment ${EXP}"
echo "Log file will be in = $LOGFILE" 

if [ "$ATM" -eq 1 ]; then
    echo "IFS processing: yes"
else
    echo "IFS processing: no"
fi

if [ "$OCE" -eq 1 ]; then
    echo "NEMO processing: yes"
else
    echo "NEMO processing: no"
fi

echo "Submitting jobs via Slurm..."

# Define basic options for slurm submission
BASE_OPT="EXP=$EXP,YEAR=$YEAR,USEREXP=$USEREXP,NCORES=$NCORES"
MACHINE_OPT="--account=$ACCOUNT --time $TLIMIT -n $NCORES --partition=$PARTITION --mem=$MEMORY"

# Atmospheric submission
# For IFS we submit one job for each month
if [ "$ATM" -eq 1 ] ; then

    # Loop on months
    #for MON in $(seq 1 12); do
    for MON in 1 ; do
	    OPT_ATM="$BASE_OPT,ATM=$ATM,OCE=0"
	    #echo OPT_ATM=${OPT_ATM}
	    JOBID=$($SUBMIT $MACHINE_OPT --job-name=proc_ifs-${YEAR}-${MON} --output=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.err --export=${OPT_ATM} ./cmor_mon_filter.sh)
    done

fi

# Because NEMO output files corresponding to same leg are all in one big file, we don't
# need to submit a job for each month, only one for each leg
if [ "$OCE" -eq 1 ]; then
    OPT_OCE="$BASE_OPT,ATM=0,OCE=$OCE"
    #echo OPT_OCE=${OPT_OCE}
    JOBID=$($SUBMIT $MACHINE_OPT --job-name=proc_nemo-${YEAR} --output=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.err --export=${OPT_OCE} ./cmor_mon_filter.sh)
fi

echo "Jobs submitted!"
echo "========================================================="

# End of script
exit 0



