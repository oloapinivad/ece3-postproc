#!/usr/bin/env bash

usage()
{
   echo "Usage:"
   echo "       autocmor.sh [-a account] [-u USERexp] EXP -r RESO"
   echo
   echo "Options are:"
   echo "   -a ACCOUNT  : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT:-unknown})"
   echo "   -u USERexp  : alternative user owner of the experiment, (default: $USER)"
   echo "   -r RESO     : horizontal resolution of IFS (default: T255)"
}

set -ue

INDEX=1
RESO=${RESO:-T255}

# -- default options
account="${ECE3_POSTPROC_ACCOUNT-}"
options=""

# -- options
while getopts "hu:a:r:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        u)  options="${options} -u $OPTARG"
            USEREXP=$OPTARG
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

if [ $# -ne 1 ]; then
   usage
   exit 1
fi

EXP=$1

echo "$EXP"
USEREXP=${USEREXP:-$USER}
queue_cmd="qstat -f"

config=${ECE3_POSTPROC_MACHINE}
. ${ECE3_POSTPROC_TOPDIR}/ece2cmor3_support/config/config_${config}.sh
cd ${ECE3_POSTPROC_TOPDIR}/ece2cmor3_support


# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

echo "$USEREXP"

IFSRESULTS0='$WORKDIR/Output_${year}/IFS'

# -- Find first and last year
year="*"
YEAR_LAST=$( basename $(eval echo $IFSRESULTS0/ICMSH${EXP}+????12 | rev | cut -f1 -d" " | rev) | cut -c11-14)
YEAR_ZERO=$( basename $(eval echo $IFSRESULTS0/ICMSH${EXP}+????12 | cut -f1 -d" ") | cut -c11-14)

# -- exit if no years are found
if [[ ${YEAR_ZERO} == "????" ]] || [[ ${YEAR_ZERO} == "????" ]] ; then 
   echo "Experiment $EXP not found in $IFSRESULTS0! Exiting!"
   exit
fi

# -- on which years are we running
echo "First year is ${YEAR_ZERO}"
echo "First year will be skipped"
echo "Last year is ${YEAR_LAST}"

# -- Write and submit one script per year
for YEAR in $(seq $(( YEAR_ZERO + 1 )) ${YEAR_LAST})
do 
    echo; echo ---- $YEAR -----
    # -- If postcheck exists plot it, then exit! 
    if [ -f  $(eval echo ${ROOTPATH}/validate_$YEAR.txt ) ] 
    then
	cat $(eval echo ${ROOTPATH}/validate_$YEAR.txt )
    else
	echo "POSTPROC"
	 #-- check if postproc is already, the exit
	ll=$(echo $(${queue_cmd} | grep "ifs-${EXP}-${YEAR}\|nemo-${EXP}-${YEAR}\|merge-${EXP}-${YEAR}\|validate-${EXP}-${YEAR}"))
	if [[ ! -z $ll ]] ; then
            echo "CMOR postprocessing for year $YEAR already going on..."
            continue
        fi
	ll=$(echo $(${queue_cmd} | grep "rbld-${EXP}"))
        if [[ ! -z $ll ]] ; then
            echo "NEMO Rebuild is running, unsafe running CMORization..."
            continue
        fi

	./submit_year.sh -e $EXP -y $YEAR -j $YEAR_ZERO -i $INDEX -r $RESO  \
                        -a 1 -o 1 -m 1 -v 1
	
    fi
done
