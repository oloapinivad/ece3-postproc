#!/bin/bash

usage()
{
   echo "Usage: .sh [-a account] [-u user] exp year1 year2"
   echo "Rebuild Nemo data at all time frequencies for experiment exp of user (optional)"
   echo "Options are:"
   echo "-a account    : specify a different special project for accounting (default: ${ECE3_POSTPROC_ACCOUNT-})"
   echo "-u user       : analyse experiment of a different user (default: $USER)"
}

set -ue

# -- default options
account="${ECE3_POSTPROC_ACCOUNT-}"
options=""
nprocs=12

while getopts "h?u:a:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    u)  USERexp=$OPTARG
        ;;
    a)  account=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -lt 1 ]; then
   usage 
   exit 0
fi


# load user and machine specifics
# -- get submit command
CONFDIR=${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}
. $CONFDIR/conf_nemorbld_$ECE3_POSTPROC_MACHINE.sh

# -- Scratch dir (location of submit script and its log, and temporary files)
OUT=$SCRATCH/tmp_ecearth3
mkdir -p $OUT/log

# -- submit script
tgt_script=$OUT/rbld_$1_$2_$3.job

echo "Launched timeseries analysis for experiment $1 of user $USERexp"

sed "s/<EXPID>/$1/" < ${CONFDIR}/rb_$ECE3_POSTPROC_MACHINE.tmpl > $tgt_script 
sed -i "s/<ACCOUNT>/$account/"  $tgt_script
sed -i "s/<USER>/$USER/"  $tgt_script
sed -i "s/<JOBID>/rbld/"  $tgt_script
sed -i "s/<MEM>/24GB/"  $tgt_script
sed -i "s/<TOTTIME>/10:00:00/"   $tgt_script
sed -i "s/<THREADS>/18/"  $tgt_script
sed -i "s/<IFS_PROCS>/1/"   $tgt_script
sed -i "s/<NEMO_PROCS>/18/"   $tgt_script
sed -i "s|<OUT>|$OUT|" $tgt_script

echo ../nemo_rebuild/nemo_rebuilder.sh $1 $2 $3 >> $tgt_script


${submit_cmd} $tgt_script
squeue -u $USER
