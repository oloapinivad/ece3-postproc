#!/usr/bin/env bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Automatico cmorization tool
# Estimates the presence of cmorized output and submit a chain of jobs
# Do some checks to avoid useless resubmissions

usage()
{
   echo "Usage:"
   echo "       autocmor.sh [-a account] [-u USERexp] -r RESO expname"
   echo
   echo "Options are:"
   echo "   -a ACCOUNT  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})"
   echo "   -u USERexp  : alternative user owner of the experiment, (default: $USER)"
   echo "   -r RESO     : horizontal resolution of IFS (default: T255)"
}

set -ue

# -- default options
account="${ECE3_POSTPROC_ACCOUNT-}"
options=""
RESO=${RESO:-T255}

# -- options
while getopts "hu:a:r:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        u)  options="${options} -u $OPTARG"
            USERexp=$OPTARG
            ;;
        a)  account=$OPTARG
            ;;
	r)  RESO=$OPTARG
            ;;
        *)  usage
            exit 1
    esac
done
shift $((OPTIND-1))

#setting expname
expname=$1
echo "$expname"
echo "$RESO"

# load user and machine specifics
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

# -- Find first and last year
year="*"
year_LAST=$( basename $(eval echo $IFSRESULTS0/ICMSH${expname}+????12 | rev | cut -f1 -d" " | rev) | cut -c11-14)
year_ZERO=$( basename $(eval echo $IFSRESULTS0/ICMSH${expname}+????12 | cut -f1 -d" ") | cut -c11-14)

# -- exit if no years are found
if [[ ${year_ZERO} == "????" ]] || [[ ${year_ZERO} == "????" ]] ; then 
   echo "Experiment $expname not found in $IFSRESULTS0! Exiting!"
   exit
fi

# -- on which years are we running
echo "First year is ${year_ZERO}"
echo "Last year is ${year_LAST}"
echo "Due to the lastout I will not run it on the last year"

#year_LAST=1955 #wrong to run checks

# -- Write and submit one script per year
for year in $(seq $(( year_ZERO )) $((year_LAST - 1)))
do 
    echo; echo ---- $year -----
    # -- If postcheck exists plot it, then exit! 
    #ROOTDIR=$( echo $( eval echo $ECE3_POSTPROC_CMORDIR )  | rev | cut -f2- -d"/" | rev)
    #mkdir -p $ROOTDIR
    if [ -f  $INFODIR/${expname}/PrePARE_${expname}_${year}.txt  ] 
    then
	cat $INFODIR/${expname}/PrePARE_${expname}_$year.txt
    else
	echo "LAUNCHIN' CMORIZATION..."
	echo $( eval echo $ECE3_POSTPROC_CMORDIR )
	 #-- check if postproc is already, the exit
	ll=$(echo $(${QUEUE_CMD} | grep "ifs-${expname}-${year}\|nemo-${expname}-${year}\|merge-${expname}-${year}\|validate-${expname}-${year}"))
	if [[ ! -z $ll ]] ; then
            echo "IFS CMOR postprocessing for year $year already going on..."
            continue
        fi
	ll=$(echo $(${QUEUE_CMD} | grep "rbld-${expname}"))
        if [[ ! -z $ll ]] ; then
            echo "NEMO Rebuild is running, unsafe running CMORization..."
            continue
        fi

	TGTDIR=$( eval echo $ECE3_POSTPROC_CMORDIR )
	echo "Let's start Cmorization, cleaning $TGTDIR..."
	rm -rf $TGTDIR
	echo "Submitting $EASYDIR/submit_year.sh"
	#submitting command	
	$EASYDIR/run_1year_ece2cmor3.sh -e $expname -y $year -r $RESO  \
                                 -a 1 -o 1 -v 0 -p 1 -u $USERexp
	
    fi
done

$QUEUE_CMD -u $USER
