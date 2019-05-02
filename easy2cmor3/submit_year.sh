#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Adapted from a script by Gijs van den Oord and Kristian Strommen

###############################################################################
#
# Filter and CMORize one year of EC-Earth output: uses CMIP6 tables only.
# This script submits 12+1 jobs, each filtering/cmorizing one month of data.
# In a delayed framework provides also data merging and validation.
#
#
# ATM=1 means process IFS data.
# OCE=1 means process NEMO data (default is 0).
# PREPARE=1 means that PrePARE validation will be run.
# CORRECT=1 means that the script for data correction is active
# RESO is used to set machine dependent properties for job submission.
# STARTTIME is used for IFS reference date (fundamental for concatenation).
#
################################################################################

set -ue

#---REQUIRED ARGUMENTS----#
expname=cj02
year=1851

#---DEFAULT INPUT ARGUMENT----#
RESO=T255 # resolition, to set accorindgly machine dependent requirements
USERexp=${USERexp:-ccjh}  #extra: allows analysis of experiment owned by different user
ATM=1
OCE=1
CORRECT=0 #flag for correction
PREPARE=0 #flag for PrePARE check

# options controller 
OPTIND=1
while getopts "h:e:y::a:o:p:c:i:r:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: submit_year.sh -e <experiment name> -y <year> -i \
                -a <process atmosphere (0,1): default 0> -o <process ocean (0,1): default 0> -u <userexp> \
		-m <merge into yearly (0,1): default 0> -v <validate data (0,1): default 0> \
		-p <check with PrePARE (0,1): default 0> -c <launch data corrector (0,1): default 0> \
		-r <resolution (T255,T511): default T255> "
          exit 0 ;;
    e)    expname=$OPTARG ;;
    y)    year=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    p)    PREPARE=$OPTARG ;;
    c)    CORRECT=$OPTARG ;;
    u)    USERexp=$OPTARG ;;
    r)	  RESO=$OPTARG ;;
    esac
done
shift $((OPTIND-1))

#--------config file-----
# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

 # load utilities/
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# load user and machine specifics
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

# A bit of log...
echo "========================================================="
echo "Processing and CMORizing year $year of experiment ${expname}"
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

if [ "$PREPARE" -eq 1 ]; then
    echo "PrePARE check: yes"
else
    echo "PrePARE check: no"
fi

if [ "$CORRECT" -eq 1 ]; then
    echo "Correction metadata: yes"
    echo "Disabling all the other options!"
    ATM=0; OCE=0; MERGE=0
else
    echo "Correction metadata files: no"
fi

echo "Submitting jobs via $SUBMIT..."

# Machine and process options
BASE_OPT="expname=$expname,year=$year,USERexp=$USERexp"
OPT_ATM="$BASE_OPT,ATM=$ATM,OCE=0,NCORESATM=$NCORESATM"
OPT_OCE="$BASE_OPT,ATM=0,OCE=$OCE,NCORESOCE=$NCORESOCE"
OPT_COR="year=${year},expname=${expname}"
OPT_PRE=${OPT_COR}

#---- DEPRECATED ----
# Define basic options for SLURM sbatch submission
#if [[ "$SUBMIT" == "sbatch" ]] ; then
	#MACHINE_OPT="--account=$ACCOUNT --time $TLIMIT --partition=$PARTITION --mem=$MEMORY"
	#JOB_ATM='$SUBMIT ${MACHINE_OPT} --export=MON=${MON},${OPT_ATM} -n $NCORESATM --job-name=ifs-${expname}-${year}-${MON}
                 #--output=$LOGFILE/cmor_${expname}_${year}_${MON}_ifs_%j.out --error=$LOGFILE/cmor_${expname}_${year}_${MON}_ifs_%j.err
                 #./cmorize_month.sh'
	#JOB_OCE='$SUBMIT ${MACHINE_OPT} --export=${OPT_OCE} -n $NCORESOCE --job-name=nemo-${expname}-${year}
                #--output=$LOGFILE/cmor_${expname}_${year}_nemo_%j.out --error=$LOGFILE/cmor_${expname}_${year}_nemo_%j.err
                #./cmorize_month.sh'
	#JOB_MER='$SUBMIT ${MACHINE_OPT} --export=${OPT_MERGE} -n $NCORESMERGE 
                #--begin=now+${DELTAMIN}minutes  --job-name=merge-${expname}-${year}
                #--output=$LOGFILE/merge_${expname}_${year}_%j.out --error=$LOGFILE/merge_${expname}_${year}_%j.err
                #./merge_month.sh'
	#JOB_VAL='$SUBMIT --account=$ACCOUNT --time $TCHECK --partition=$PARTITION --mem=${MEMORY2} -n $NCORESVALID
                #--export=${OPT_VALID} --job-name=validate-${expname}-${year}  --dependency=afterok:$JOBIDMERGE
                #--output=$LOGFILE/validate_${expname}_${year}_%j.out --error=$LOGFILE/validate_${expname}_${year}_%j.err
                #./validate.sh'
	#JOB_COR='$SUBMIT --account=$ACCOUNT --time 01:00:00 --partition=$PARTITION --mem=${MEMORY} -n $NCORESCORRECT
                #--export=${OPT_COR} --job-name=correct-${expname}-${year} --begin=now+${DELTAMIN}minutes
                #--output=$LOGFILE/correct_${expname}_${year}_%j.out --error=$LOGFILE/correct_${expname}_${year}_%j.err
                #./correct_rename.sh'
	#JOB_PRE='$SUBMIT --account=$ACCOUNT --time 00:10:00 --partition=$PARTITION --mem=${MEMORY} -n $NCORESPREPARE
                #--export=${OPT_PRE} --job-name=PrePARE-${expname}-${year}  --dependency=afterok:$JOBIDMERGE
                #--output=$LOGFILE/PrePARE_${expname}_${year}_%j.out --error=$LOGFILE/PrePARE_${expname}_${year}_%j.err
                #./call_PrePARE.sh'


# define options for PBS qsub submission
if [[ "$SUBMIT" == "qsub" ]] ; then
        MACHINE_OPT="-l EC_billing_account=$ACCOUNT -l walltime=$TLIMIT -q $PARTITION -l EC_memory_per_task=$MEMORY -l EC_total_tasks=1"
        JOB_ATM='$SUBMIT ${MACHINE_OPT} -v ${OPT_ATM} -l EC_threads_per_task=$NCORESATM -N ifs-${expname}-${year}
                 -o $LOGFILE/cmor_${expname}_${year}_ifs.out -e $LOGFILE/cmor_${expname}_${year}_ifs.err
                 ./cmorizer_cmip6.sh'
        JOB_OCE='$SUBMIT ${MACHINE_OPT} -v ${OPT_OCE} -l EC_threads_per_task=$NCORESOCE -N nemo-${expname}-${year}
                 -o $LOGFILE/cmor_${expname}_${year}_nemo.out -e $LOGFILE/cmor_${expname}_${year}_nemo.err
                 ./cmorizer_cmip6.sh'
	JOB_COR='$SUBMIT -l EC_billing_account=$ACCOUNT -l walltime=01:00:00 -q $PARTITION -l EC_memory_per_task=${MEMORY}
                -l EC_threads_per_task=$NCORESCORRECT -v ${OPT_COR} -N correct-${expname}-${year}
                -o $LOGFILE/correct_${expname}_${year}.out  -e $LOGFILE/correct_${expname}_${year}.err
                ./correct_rename.sh'
	JOB_PRE='$SUBMIT -l EC_billing_account=$ACCOUNT -l walltime=00:20:00 -q $PARTITION -l EC_memory_per_task=${MEMORY}
                -l EC_threads_per_task=$NCORESCORRECT -v ${OPT_PRE} -W depend=afterok:$JOBIDNEMO$JOBIDIFS -N PrePARE-${expname}-${year}
                -o $LOGFILE/PrePARE_${expname}_${year}.out  -e $LOGFILE/PrePARe_${expname}_${year}.err
                ./call_PrePARE.sh'
fi

# Because NEMO output files corresponding to same leg are all in one big file, we don't
# need to submit a job for each month, only one for each leg
if [ "$OCE" -eq 1 ]; then
        JOBID=$(eval ${JOB_OCE})
        if [[ $SUBMIT == "sbatch" ]] ; then
                JOBIDNEMO=$(echo $JOBID | cut -f4 -d" ")
        elif [[  $SUBMIT == "qsub" ]] ; then
                JOBIDNEMO=$JOBID
        fi
fi


# Atmospheric submission
# For IFS we submit one job for each month
if [ "$ATM" -eq 1 ] ; then

	JOBIDIFS=""
	#loop on months
        JOBID=$(eval ${JOB_ATM})
        if [[ $SUBMIT == "sbatch" ]] ; then
                JOBIDIFS=$(echo $JOBID | cut -f4 -d" ")
        elif [[  $SUBMIT == "qsub" ]] ; then
                JOBIDIFS=${JOBIDIFS}:$JOBID
        fi

fi

# PrePARE submitting, delayed with dependency 
if [ "$PREPARE" -eq 1 ] ; then
        eval ${JOB_PRE}
fi

# Corrector submitting
if [ "$CORRECT" -eq 1 ] ; then
        eval ${JOB_COR}
fi

echo "Jobs submitted!"
echo "========================================================="

# End of script
exit 0

