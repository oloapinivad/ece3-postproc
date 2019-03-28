#!/usr/bin/env bash

usage()
{
   echo "Usage: "
   echo "  amwg.sh [-a account] [-d dependency] [-r altdir] [-u USERexp] EXP YEAR1 YEAR2"
   echo
   echo "Submit to a job scheduler an AMWG analysis of experiment EXP in years"
   echo " YEAR1 to YEAR2. This is basically a wrapper around the amwg_modobs.sh script."
   echo 
   echo "Options are:"
   echo "   -a account    : specify a different special project for HPC accounting (default: ${ECE3_POSTPROC_ACCOUNT-})"
   echo "   -r RUNDIR     : fully qualified path to another user EC-Earth top RUNDIR [NOT TESTED YET!]"
   echo "                   that is RUNDIR/EXP must exists and be readable"
   echo "   -u USERexp    : alternative user owner of the experiment, default $USER"
   echo "   -y EXP2       : the model run EXP compared with an other model run (EXP2 that is the control case)"
   echo "                   check if modmod is ON"
}

set -ue

# -- default option
account=${ECE3_POSTPROC_ACCOUNT-}
ALT_RUNDIR=""
dependency=
options=""

while getopts "h?a:ury:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        d)  dependency=$OPTARG
            ;;
        r)  options="${options} -r $OPTARG"
            ALT_RUNDIR=$OPTARG
            ;;
        u)  options="${options} -u $OPTARG"
            USERexp=$OPTARG
            ;;
        a)  account=$OPTARG
            ;;
        *)  usage
            exit 1
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 3 ]; then
    echo; echo "*EE* missing arguments"; echo
    usage
    exit 1
fi

echo "exp2 $EXPID2" 

# -- Sanity check (from amwg_modobs.sh, repeated here for "before submission" error catch) 
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

# check that we have a 4-digit number for the year input
if [[ ! $2 =~ ^[0-9]{4}$ ]]
then
    echo ;echo "*EE* argument YEAR1 (=$2) should be a 4-digit integer"; echo
    usage
    exit 1
fi
if [[ ! $3 =~ ^[0-9]{4}$ ]]
then
    echo; echo "*EE* argument YEAR2 (=$3) should be a 4-digit integer"; echo
    usage
    exit 1
fi

# check we have a 4-letter experiment
if [[ ! $1 =~ ^[a-zA-Z0-9_]{4}$ ]]
then
    echo; echo "*EE* argument EXP (=$1) should be a 4-letter string"; echo
    usage
    exit 1
fi

# set variables which can be eval'd
EXPID=$1

# -- Scratch dir (logs end up there)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

# -- get OUTDIR, submit command
CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}
. ${CONFDIR}/conf_amwg_${ECE3_POSTPROC_MACHINE}.sh

# -- check input dir exists
if [[ -n $ALT_RUNDIR ]]
then
    outdir=$ALT_RUNDIR/mon
else
    outdir=$(eval echo ${ECE3_POSTPROC_POSTDIR})/mon
fi
[[ ! -d $outdir ]] && echo "*EE* Experiment HiresClim2 output dir $outdir does not exist!" && exit 1


# -- check amwg_modmod on
if (( modmodcheck ))
then
	# -- submit script
	Y1=$2
	Y2=$3

	tgt_script=$OUT/amwg_$1_${EXPID2}_$2_$3.job

	echo "$1"
	echo "$2"
	echo "$3"
	echo "$EXPID2"

	sed "s/<EXPID>/$1-$EXPID2/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script
	sed -i "s/<Y1>/$3/" $tgt_script
	[[ -n $account ]] && \
	    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
	    sed -i "/<ACCOUNT>/ d" $tgt_script
	sed -i "s/<JOBID>/amwg/" $tgt_script
	sed -i "s|<OUT>|$OUT|" $tgt_script
   
	echo ../amwg/amwg_modmod.sh ${options} $1 $EXPID2 $2 $3 >>  $tgt_script
	echo "*EE* check modmod is ON"

else

	# -- submit script
	Y1=$2

	tgt_script=$OUT/amwg_$1_$2_$3.job

	sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script
	sed -i "s/<Y1>/$2/" $tgt_script
	[[ -n $account ]] && \
	    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
	    sed -i "/<ACCOUNT>/ d" $tgt_script
	sed -i "s/<JOBID>/amwg/" $tgt_script
	sed -i "s/<Y1>/$2/" $tgt_script
	sed -i "s|<OUT>|$OUT|" $tgt_script

	echo ../amwg/amwg_modobs.sh ${options} $1 $2 $3 >>  $tgt_script
	echo "*EE* check modobs is ON"
#sed "s/<EXPID>/$1/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script
#[[ -n $account ]] && \
#    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
#    sed -i "/<ACCOUNT>/ d" $tgt_script
#
	[[ -n $dependency ]] && \
	    sed -i "s/<DEPENDENCY>/$dependency/" $tgt_script || \
	    sed -i "/<DEPENDENCY>/ d" $tgt_script


fi

${submit_cmd} $tgt_script
