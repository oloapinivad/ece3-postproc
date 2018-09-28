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
# Paolo Davini (Apr 2018) - based on a script by Gijs van den Oord and Kristian Strommen
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
USEREXP=${USEREXP:-$USER}  #extra: allows analysis of experiment owned by different user
MONTH=0 #if month=0, then loop on all months (IFS only)
ATM=0
OCE=0
MERGE=0 #flag for merging
VALID=0 #flag for validation
STARTTIME=1950-01-01 #very important to allow correct merging

#---PARALLELIZATION OPTIONS---#
NCORESATM=8 #parallelization is available
NCORESOCE=1
NCORESMERGE=24 #parallelization is available
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

#--------config file-----
config=${ECE3_POSTPROC_MACHINE}
. ${ECE3_POSTPROC_TOPDIR}/ece2cmor3_support/config/config_${config}.sh
cd ${ECE3_POSTPROC_TOPDIR}/ece2cmor3_support

#-----------------------#
if [[ $MONTH -eq 0 ]] ; then
	MONS=$(seq 1 12)
else
	MONS=$MONTH
fi

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

# Machine and process options
BASE_OPT="EXP=$EXP,YEAR=$YEAR,USEREXP=$USEREXP,INDEX=$INDEX"
OPT_ATM="$BASE_OPT,ATM=$ATM,OCE=0,NCORESATM=$NCORESATM,STARTTIME=$STARTTIME"
OPT_OCE="$BASE_OPT,ATM=0,OCE=$OCE,NCORESOCE=$NCORESOCE"
DELTAMIN=$(( (YEAR-YEAR0+1) * $DELTA ))
OPT_MERGE="YEAR=${YEAR},EXP=${EXP}"
OPT_VALID="YEAR1=${YEAR},YEAR2=${YEAR},EXP=${EXP},MONTHS=13"


# Define basic options for slurm submission
if [[ "$SUBMIT" == "sbatch" ]] ; then
	MACHINE_OPT="--account=$ACCOUNT --time $TLIMIT --partition=$PARTITION --mem=$MEMORY"
	JOB_ATM='$SUBMIT ${MACHINE_OPT} --export=MON=${MON},${OPT_ATM} -n $NCORESATM --job-name=ifs-${EXP}-${YEAR}-${MON}
                 --output=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs_%j.err
                 ./cmorize_month.sh'
	JOB_OCE='$SUBMIT ${MACHINE_OPT} --export=${OPT_OCE} -n $NCORESOCE --job-name=nemo-${EXP}-${YEAR}
                --output=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.out --error=$LOGFILE/cmor_${EXP}_${YEAR}_nemo_%j.err
                ./cmorize_month.sh'
	JOB_MER='$SUBMIT ${MACHINE_OPT} --export=${OPT_MERGE} -n $NCORESMERGE --begin=now+${DELTAMIN}minutes
                 --job-name=merge-${EXP}-${YEAR} --output=$LOGFILE/merge_${EXP}_${YEAR}_%j.out --error=$LOGFILE/merge_${EXP}_${YEAR}_%j.err
                ./merge_month.sh'
	JOB_VAL='$SUBMIT --account=$ACCOUNT --time $TCHECK --partition=$PARTITION --mem=${MEMORY2} -n $NCORESVALID
                --export=${OPT_VALID} --dependency=afterok:$JOBIDMERGE --job-name=validate-${EXP}-${YEAR}
                --output=$LOGFILE/validate_${EXP}_${YEAR}_%j.out --error=$LOGFILE/validate_${EXP}_${YEAR}_%j.err
                ./validate.sh'

elif [[ "$SUBMIT" == "qsub" ]] ; then
	MACHINE_OPT="-l EC_billing_account=$ACCOUNT -l walltime=$TLIMIT -q $PARTITION -l EC_memory_per_task=$MEMORY -l EC_total_tasks=1"
	JOB_ATM='$SUBMIT ${MACHINE_OPT} -v MON=${MON},${OPT_ATM} -l EC_threads_per_task=$NCORESATM -N ifs-${EXP}-${YEAR}-${MON}
                 -o $LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs.out -e $LOGFILE/cmor_${EXP}_${YEAR}_${MON}_ifs.err
                 ./cmorize_month.sh'
	JOB_OCE='$SUBMIT ${MACHINE_OPT} -v ${OPT_OCE} -l EC_threads_per_task=$NCORESOCE -N nemo-${EXP}-${YEAR}
                 -o $LOGFILE/cmor_${EXP}_${YEAR}_nemo.out -e $LOGFILE/cmor_${EXP}_${YEAR}_nemo.err
                 ./cmorize_month.sh'
	hhmm=$(date +"%H%m")
	echo $hhmm
	DELTAMIN=$((DELTAMIN + hhmm))
	echo $DELTAMIN
	JOB_MER='$SUBMIT ${MACHINE_OPT} -v ${OPT_MERGE} -l EC_threads_per_task=$NCORESMERGE -a $DELTAMIN
                 -N merge-${EXP}-${YEAR} -o $LOGFILE/merge_${EXP}_${YEAR}.out -e $LOGFILE/merge_${EXP}_${YEAR}.err
                ./merge_month.sh'
	JOB_VAL='$SUBMIT -l EC_billing_account=$ACCOUNT -l walltime=$TCHECK -q $PARTITION -l EC_memory_per_task=${MEMORY2}
                -l EC_threads_per_task=$NCORESVALID -v ${OPT_VALID} -W depend=afterok:$JOBIDMERGE -N validate-${EXP}-${YEAR}
                -o $LOGFILE/validate_${EXP}_${YEAR}.out  -e $LOGFILE/validate_${EXP}_${YEAR}.err
                ./validate.sh'

fi


# Atmospheric submission
# For IFS we submit one job for each month
if [ "$ATM" -eq 1 ] ; then

	# Loop on months
    	#MONS=1
    	for MON in $MONS ; do
		#echo ${JOB_ATM}
		eval ${JOB_ATM}
	done

fi

# Because NEMO output files corresponding to same leg are all in one big file, we don't
# need to submit a job for each month, only one for each leg
if [ "$OCE" -eq 1 ]; then
    	eval ${JOB_OCE}
fi

# Merger submission, delayed by $DELTA time per year
if [ "$MERGE" -eq 1 ] ; then
    	JOBID=$(eval ${JOB_MER})
	if [[ $SUBMIT == "sbatch" ]] ; then 
		JOBIDMERGE=$(echo $JOBID | cut -f4 -d" ")
	elif [[  $SUBMIT == "qsub" ]] ; then 
		JOBIDMERGE=$JOBID
	fi
	echo $JOBIDMERGE
fi

# Validator submission, delayed with dependency
if [ "$VALID" -eq 1 ] ; then
	eval ${JOB_VAL}
fi



echo "Jobs submitted!"
echo "========================================================="

# End of script
exit 0



