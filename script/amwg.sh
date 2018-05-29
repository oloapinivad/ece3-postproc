#!/usr/bin/env bash

usage()
{
   echo "Usage: "
   echo "  amwg.sh [-u USERexp] [-r RUNDIR] [-a ACCOUNT] [-y EXP2] EXP YEAR1 YEAR2"
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

set -e

# -- default option
account=$ECE3_POSTPROC_ACCOUNT
ALT_RUNDIR=""
modmodcheck=0
options=""

while getopts "h?a:ury:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        u)  USERexp=$OPTARG
            ;;
        a)  account=$OPTARG
            ;;
        y)  options="${options} -y $OPTARG"
            EXP2=$OPTARG
            modmodcheck=1
            ;;
        r)  ALT_RUNDIR=$OPTARG
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 3 ]; then
   echo; echo "*EE* missing arguments"; echo
   usage
   exit 1
fi

echo "exp2 $EXP2" 

# -- Sanity check (from amwg_modobs.sh, repeated here for "before submission" error catch) 
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
#[[ -z $ECE3_POSTPROC_RUNDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 

# -- Scratch dir (logs end up there)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT

CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}

# -- check options for amwg_modobs.sh
#if [[ -n $ALT_RUNDIR ]]
#then
    # test alternate dir (from amwg_modobs.sh, repeated here for "before submission" error catch) 
#    outdir=$ALT_RUNDIR/$1/post
#    [[ ! -d $outdir ]] && echo "User experiment output $outdir does not exist!" && exit1
#    amwg_opt="-r $ALT_RUNDIR"
#fi

# -- get OUTDIR, submit command
. ${CONFDIR}/conf_amwg_${ECE3_POSTPROC_MACHINE}.sh

# -- check amwg_modmod on
if (( modmodcheck ))
then
# -- submit script
Y1=$2
Y2=$3

tgt_script=$OUT/amwg_$1_${EXP2}_$2_$3.job

echo "$1"
echo "$2"
echo "$3"
echo "$EXP2"

sed "s/<EXPID>/$1$EXP2/" < ${CONFDIR}/header_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script
sed -i "s/<Y1>/$3/" $tgt_script
[[ -n $account ]] && \
    sed -i "s/<ACCOUNT>/$account/" $tgt_script || \
    sed -i "/<ACCOUNT>/ d" $tgt_script
sed -i "s/<JOBID>/amwg/" $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script
   
    echo ../amwg/amwg_modmod.sh $1 $EXP2 $2 $3 >>  $tgt_script
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
sed -i "s|<OUT>|$OUT|" $tgt_script

    echo ../amwg/amwg_modobs.sh $1 $2 $3 >>  $tgt_script
    echo "*EE* check modobs is ON"

fi

${submit_cmd} $tgt_script
