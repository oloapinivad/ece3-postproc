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
expname=ch00
year=1850

#---DEFAULT INPUT ARGUMENT----#
RESO=T255 # resolition, to set accorindgly machine dependent requirements
USERexp=${USERexp:-ccpd}  #extra: allows analysis of experiment owned by different user
ATM=1
OCE=0
VEG=0
CORRECT=0 #flag for correction
PREPARE=0 #flag for PrePARE check
NCT=0 # flag for nctime
QA=0 # flag for QA-DKRZ

autoconfig=false

# options controller 
#OPTIND=1
while getopts "h:e:y:a:o:p:c:r:v:u:n:q:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: submit_year.sh -e <experiment name> -y <year> \
                -a <process atmosphere (0,1): default 0> -o <process ocean (0,1): default 0> -u <userexp> \
		-v <process vegetation (0,1): default 0>
		-p <check with PrePARE (0,1): default 0> -c <launch data corrector (0,1): default 0> \
		-r <resolution (T255,T511): default T255> "
          exit 0 ;;
    e)    expname=$OPTARG ;;
    y)    year=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    v)	  VEG=$OPTARG ;;
    p)    PREPARE=$OPTARG ;;
    c)    CORRECT=$OPTARG ;;
    u)    USERexp=$OPTARG ;;
    r)	  RESO=$OPTARG ;;
    q)    QA=$OPTARG ;;
    n)    NCT=$OPTARG ;;
    esac
done
#shift $((OPTIND-1))

#--------config file-----
# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

 # load utilities/
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# load user and machine specifics
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}/scripts

# checks
if [[ $QA -eq 1 ]] || [[ $NCT -eq 1 ]] ; then
	autoconfig=false
fi

# auto-configurator: use automatic definition of requirements
if [[ $autoconfig == true ]] ; then
	. ${EASYDIR}/config_and_create_metadata.sh $expname
	case $model in  
		EC-EARTH-AOGCM)  ATM=1 ; OCE=1 ; VEG=0 ;;
		EC-EARTH-Veg)	 ATM=1 ; OCE=1 ; VEG=1 ;;	
	esac
	[[ $exptype == "amip" ]] && OCE=0 
fi
	


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

if [ "$VEG" -eq 1 ]; then
    echo "LPJG processing: yes"
else
    echo "LPJG processing: no"
fi

if [ "$PREPARE" -eq 1 ]; then
    echo "PrePARE check: yes"
else
    echo "PrePARE check: no"
fi

if [ "$QA" -eq 1 ]; then
    echo "QA-DKRZ check: yes"
else
    echo "QA-DKRZ check: no"
fi

if [ "$NCT" -eq 1 ]; then
    echo "nctime check: yes"
else
    echo "nctime check: no"
fi

if [ "$CORRECT" -eq 1 ]; then
    echo "Correction metadata: yes"
    echo "Disabling all the other options!"
    ATM=0; OCE=0; VEG=0
else
    echo "Correction metadata files: no"
fi

echo "Submitting jobs via $SUBMIT..."

# Machine and process options
BASE_OPT="expname=$expname,year=$year,USERexp=$USERexp"
OPT_ATM="$BASE_OPT,ATM=1,OCE=0,VEG=0,NCORESATM=$NCORESATM"
OPT_OCE="$BASE_OPT,ATM=0,OCE=1,VEG=0,NCORESOCE=$NCORESOCE"
OPT_VEG="$BASE_OPT,ATM=0,OCE=0,VEG=1,NCORESOCE=$NCORESOCE"
OPT_COR="year=${year},expname=${expname}"
OPT_PRE=${OPT_COR}
OPT_QA="expname=${expname},NCORESQA=$NCORESQA"
OPT_NCT="expname=${expname},NCORESNCTIME=$NCORESNCTIME"
JOBMEMO=""


# define options for PBS qsub submission
if [[ "$SUBMIT" == "qsub" ]] ; then
        MACHINE_OPT="-l EC_billing_account=$ACCOUNT -q $PARTITION -l EC_memory_per_task=$MEMORY -l EC_hyperthreads=1"
        JOB_ATM='$SUBMIT ${MACHINE_OPT} -l walltime=$TLIMIT -v ${OPT_ATM} -l EC_threads_per_task=$NCORESATM -N ifs-${expname}-${year}
                 -o $LOGFILE/cmor_${expname}_${year}_ifs.out -e $LOGFILE/cmor_${expname}_${year}_ifs.err
                 ./call_ece2cmor3.sh'
        JOB_OCE='$SUBMIT ${MACHINE_OPT} -l walltime=$TLIMIT -v ${OPT_OCE} -l EC_threads_per_task=$NCORESOCE -N nemo-${expname}-${year}
                 -o $LOGFILE/cmor_${expname}_${year}_nemo.out -e $LOGFILE/cmor_${expname}_${year}_nemo.err
                 ./call_ece2cmor3.sh'
	JOB_VEG='$SUBMIT ${MACHINE_OPT} -l walltime=$TLIMIT -v ${OPT_VEG} -l EC_threads_per_task=$NCORESVEG -N lpjg-${expname}-${year}
                 -o $LOGFILE/cmor_${expname}_${year}_lpjg.out -e $LOGFILE/cmor_${expname}_${year}_lpjg.err
                 ./call_ece2cmor3.sh'
	JOB_COR='$SUBMIT -l ${MACHINE_OPT} -l walltime=01:00:00
                -l EC_threads_per_task=$NCORESCORRECT -v ${OPT_COR} -N correct-${expname}-${year}
                -o $LOGFILE/correct_${expname}_${year}.out  -e $LOGFILE/correct_${expname}_${year}.err
                ./correct_rename.sh'
	JOB_PRE='$SUBMIT ${MACHINE_OPT} -l walltime=$TLIMIT -l EC_threads_per_task=$NCORESPREPARE -v ${OPT_PRE} 
                 -N PrePARE-${expname}-${year} ${DEPENDENCY} -o $LOGFILE/PrePARE_${expname}_${year}.out  
                 -e $LOGFILE/PrePARE_${expname}_${year}.err ./call_PrePARE.sh'
	JOB_NCT='$SUBMIT ${MACHINE_OPT} -l walltime=08:00:00 -l EC_threads_per_task=$NCORESNCTIME -v ${OPT_NCT}  
                 -N nctime-${expname}-${year} -o $LOGFILE/nctime_${expname}_${year}.out  
                 -e $LOGFILE/nctime_${expname}_${year}.err ./call_nctime.sh'
	JOB_QA='$SUBMIT -l EC_billing_account=$ACCOUNT -q np -l EC_hyperthreads=1  
                -l walltime=36:00:00 -l EC_total_tasks=$NCORESQA -v ${OPT_QA}  -l EC_memory_per_task=2000MB
                -N QA-DKRZ-${expname}-${year} -o $LOGFILE/QA-DKRZ_${expname}_${year}.out 
                -e $LOGFILE/QA-DKRZ_${expname}_${year}.err ./call_github-qa-dkrz.sh'

fi

# Nemo submission
if [ "$OCE" -eq 1 ]; then
        JOBID=$(eval ${JOB_OCE})
        JOBMEMO=${JOBMEMO}:${JOBID}
	echo $JOBID
fi


# IFS submission
if [ "$ATM" -eq 1 ] ; then
        JOBID=$(eval ${JOB_ATM})
	JOBMEMO=${JOBMEMO}:${JOBID}
	echo $JOBID
fi

# LPJG submission
if [ "$VEG" -eq 1 ] ; then
        JOBID=$(eval ${JOB_VEG})
	JOBMEMO=${JOBMEMO}:${JOBID}
        echo $JOBID
fi

# dependency for PrePARE
if [ $ATM -eq 0 ] && [ $OCE -eq 0 ] && [ $VEG -eq 0 ] ; then
	DEPENDENCY=""
else
	DEPENDENCY="-W depend=afterany${JOBMEMO}"
fi



# PrePARE submitting, delayed with dependency 
if [ "$PREPARE" -eq 1 ] ; then
        eval ${JOB_PRE}
fi

# QA-DKRZ submitting, delayed with dependency 
if [ "$QA" -eq 1 ] ; then
        eval ${JOB_QA}
fi

# Nctime submitting, delayed with dependency 
if [ "$NCT" -eq 1 ] ; then
        eval ${JOB_NCT}
fi

# Corrector submitting
if [ "$CORRECT" -eq 1 ] ; then
        eval ${JOB_COR}
fi

echo "Jobs submitted!"
echo "========================================================="

# End of script
exit 0

