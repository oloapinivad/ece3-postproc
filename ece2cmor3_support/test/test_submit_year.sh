#!/bin/bash

###############################################################################
#
# Filter and CMORize one year of EC-Earth output: uses CMIP6 tables only.
# This script submits 12+1 jobs, each filtering/cmorizing one month of data.
# In a delayed framework provides also data merging and validation.
#
# Note that for NEMO processing, all files in the output folder will be
# processed irrespective of the MON variable, so this is only useful for IFS.
#
# ATM=1 means process IFS data.
# OCE=1 means process NEMO data (default is 0).
# MERGE=1 means that IFS files will be merged into yearly files.
# VALID=1 means that data validation by Jon Seddon will be run.
# RESO is used to set machine dependent properties for job submission.
# INDEX change the relization_index in the metadata file.
# STARTTIME is used for IFS reference date (fundamental for concatenation).
# NCORESATM/OCE/MERGE/VALID is used for parallel computation.
#
#
# Paolo Davini (Apr 2018) - based on a script by Gijs van Oord and Kristian Strommen
#
################################################################################

set -ue

#---REQUIRED ARGUMENTS----#
#EXP=det4
#YEAR=1950
#YEAR0=$YEAR

#---DEFAULT INPUT ARGUMENT----#
RESO=T255 # resolition, to set accorindgly machine dependent requirements
INDEX=1 #realization index, to change metadata
USEREXP=${USEREXP:-pdavini0}  #extra by P. davini: allows analysis of experiment owned by different user
MONTH=0 #if month=0, then loop on all months (IFS only)
ATM=1
OCE=0
MERGE=1 #flag for merging
VALID=1 #flag for validation
STARTTIME=1950-01-01 #very important to allow correct merging

#---PARALLELIZATION OPTIONS---#
NCORESATM=2 #parallelization is available
NCORESOCE=1
NCORESMERGE=1 #parallelization is available
NCORESVALID=1

# options controller 
OPTIND=1
while getopts "h:e:y:j:u:a:o:m:v:i:r:s:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: submit_year.sh -e <experiment name> -y <year> -i <realization index: default 1> \
                -a <process atmosphere (0,1): default 0> -o <process ocean (0,1): default 0> -u <userexp> \
		-m <merge into yearly (0,1): default 0> -v <validate data (0,1): default 0> \
		-j <initial year for lagged merging and validation (default: year) > \
		-r <resolution (T255,T511): default T255> -s <reference time for NetCDF (YYYY-MM-DD): default 1950-01-01>"
          exit 0 ;;
    e)    EXP=$OPTARG ;;
    y)    YEAR=$OPTARG ;;
    j)    YEAR0=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    m)    MERGE=$OPTARG ;;
    v) 	  VALID=$OPTARG ;;
    u)    USEREXP=$OPTARG ;;
    i)    INDEX=$OPTARG ;;
    r)	  RESO=$OPTARG ;;
    s)    STARTTIME=$OPTARG ;;
    esac
done
shift $((OPTIND-1))

#----machine dependent argument----#
ACCOUNT=IscrC_C2HEClim
SUBMIT="sbatch"
PARTITION=bdw_usr_prod
if [[ $RESO == T511 ]] ; then 
	MEMORY=50GB
	MEMORY2=100GB
	TLIMIT="03:59:00"
	DELTA=270
	TCHECK="09:59:00"
else
	MEMORY=10GB
	MEMORY2=${MEMORY}
	TLIMIT="00:10:00"
	DELTA=5
	TCHECK="00:10:00"
fi

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

if [ "$MERGE" -eq 1 ]; then
    echo "Merging in yearly files: yes"
else
    echo "Merging in yearly files: no"
fi

if [ "$VALID" -eq 1 ]; then
    echo "Validating files: yes"
else
    echo "Validating files: no"
fi

echo "Submitting jobs via $SUBMIT..."

# Define basic options for slurm submission
BASE_OPT="EXP=$EXP,YEAR=$YEAR,USEREXP=$USEREXP,INDEX=$INDEX"
MACHINE_OPT="--account=$ACCOUNT --time $TLIMIT --partition=$PARTITION --mem=$MEMORY"

# Atmospheric submission
# For IFS we submit one job for each month
if [ "$ATM" -eq 1 ] ; then

    # Loop on months
    for MON in $MONS ; do
	    OPT_ATM="$BASE_OPT,ATM=$ATM,OCE=0,NCORESATM=$NCORESATM,MON=$MON,STARTTIME=$STARTTIME"
	    #echo OPT_ATM=${OPT_ATM}
	    JOBID=$($SUBMIT $MACHINE_OPT -n $NCORESATM --job-name=ifs-${EXP}-${YEAR}-${MON} --output=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.err --export=${OPT_ATM} ./test_cmorize_month.sh)
    done

fi

# Because NEMO output files corresponding to same leg are all in one big file, we don't
# need to submit a job for each month, only one for each leg
if [ "$OCE" -eq 1 ]; then
    OPT_OCE="$BASE_OPT,ATM=0,OCE=$OCE,NCORESOCE=$NCORESOCE"
    #echo OPT_OCE=${OPT_OCE}
    JOBID=$($SUBMIT $MACHINE_OPT -n $NCORESOCE --job-name=nemo-${EXP}-${YEAR} --output=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.err --export=${OPT_OCE} ./test_cmorize_month.sh)
fi

# Merger submission, delayed by $DELTA time per year
if [ "$MERGE" -eq 1 ] ; then
    DELTAMIN1=$(( (YEAR-YEAR0+1)* $DELTA ))
    OPT_MERGE="YEAR=${YEAR},EXP=${EXP}"
    JOBIDMERGE=$($SUBMIT $MACHINE_OPT -n $NCORESMERGE --begin=now+${DELTAMIN1}minutes --job-name=merge-${EXP}-${YEAR} --output=$LOGFILE/merge_${YEAR}_%j.out --error=$LOGFILE/merge_${YEAR}_%j.err --export=${OPT_MERGE} ./test_merge_month.sh)
    echo $JOBIDMERGE
    JOBIDMERGE=$(echo $JOBIDMERGE | cut -f4 -d" ")
    echo $JOBIDMERGE
fi

# Validator submission, delayed
if [ "$VALID" -eq 1 ] ; then
    #DELTAMIN2=$(( (YEAR-YEAR0+1)* $DELTA + 100 + $DELTA ))
    OPT_VALID="YEAR1=${YEAR},YEAR2=${YEAR},EXP=${EXP},MONTHS=13"
    #JOBID=$($SUBMIT --account=$ACCOUNT --time $TCHECK --partition=$PARTITION --mem=$MEMORY -n $NCORESVALID --begin=now+${DELTAMIN2}minutes --job-name=validate-${EXP}-${YEAR} --output=$LOGFILE/validate_ifs_${YEAR}_%j.out --error=$LOGFILE/validate_ifs_${YEAR}_%j.err --export=${OPT_VALID} ./validate_ifs.sh)
   JOBIDVALID=$($SUBMIT --account=$ACCOUNT --time $TCHECK --partition=$PARTITION --mem=${MEMORY2} -n $NCORESVALID --dependency=afterok:$JOBIDMERGE --job-name=validate-${EXP}-${YEAR} --output=$LOGFILE/validate_ifs_${YEAR}_%j.out --error=$LOGFILE/validate_ifs_${YEAR}_%j.err --export=${OPT_VALID} ./test_validate_ifs.sh)
fi



echo "Jobs submitted!"
echo "========================================================="

# End of script
exit 0



