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
# RESO is used to set machine dependent properties for job submission
# INDEX change the relization_index in the metadata file
# NCORESATM/OCE is used for parallel computation. Oceanic part is still serial
#
# Other choices of output (output/tmp dirs etc.) are set in cmor_mon_filter.sh.
#
# Paolo Davini (Apr 2018) - based on a script by Gijs van Oord and Kristian Strommen
#
################################################################################

set -ue

#---input argument----#
EXP=${EXP:-det4}
YEAR=${YEAR:-1950}
RESO=${RESO:-T255}
INDEX=${INDEX:-1}
ATM=${ATM:-1}
OCE=${OCE:-0}
USEREXP=${USEREXP:-pdavini0}  #extra by P. davini: allows analysis of experiment owned by different user
MONTH=0 #if month=0, then loop on all months
NCORESATM=8
NCORESOCE=1

# options controller 
OPTIND=1
while getopts "h:e:y:u:a:o:i:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: submit_year.sh -e <experiment name> -y <yr> -i <realization index> \
                -a <process atmosphere (0,1): default 0> -o <process ocean (0,1): default 0> -u <userexp>"
          exit 0 ;;
    e)    EXP=$OPTARG ;;
    y)    YEAR=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    u)    USEREXP=$OPTARG ;;
    i)    INDEX=$OPTARG ;;
    esac
done
shift $((OPTIND-1))

#----machine dependent argument----#
ACCOUNT=IscrC_C2HEClim
if [[ $RESO == T511 ]] ; then 
	MEMORY=50GB
	TLIMIT="02:59:00"
else
	MEMORY=10GB
	TLIMIT="00:59:00"
fi
SUBMIT="sbatch"
PARTITION=bdw_usr_prod

#-----------------------#
if [[ $MONTH -eq 0 ]] ; then
	MONS=$(seq 1 12)
else
	MONS=$MONTH
fi

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
BASE_OPT="EXP=$EXP,YEAR=$YEAR,USEREXP=$USEREXP,INDEX=$INDEX"
MACHINE_OPT="--account=$ACCOUNT --time $TLIMIT --partition=$PARTITION --mem=$MEMORY"

# Atmospheric submission
# For IFS we submit one job for each month
if [ "$ATM" -eq 1 ] ; then

    # Loop on months
    for MON in $MONS ; do
	    OPT_ATM="$BASE_OPT,ATM=$ATM,OCE=0,NCORESATM=$NCORESATM,MON=$MON"
	    #echo OPT_ATM=${OPT_ATM}
	    JOBID=$($SUBMIT $MACHINE_OPT -n $NCORESATM --job-name=proc_ifs-${YEAR}-${MON} --output=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.err --export=${OPT_ATM} ./cmorize_month.sh)
    done

fi

# Because NEMO output files corresponding to same leg are all in one big file, we don't
# need to submit a job for each month, only one for each leg
if [ "$OCE" -eq 1 ]; then
    OPT_OCE="$BASE_OPT,ATM=0,OCE=$OCE,NCORESOCE=$NCORESOCE"
    #echo OPT_OCE=${OPT_OCE}
    JOBID=$($SUBMIT $MACHINE_OPT -n $NCORESOCE --job-name=proc_nemo-${YEAR} --output=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.err --export=${OPT_OCE} ./cmorize_month.sh)
fi

echo "Jobs submitted!"
echo "========================================================="

# End of script
exit 0



