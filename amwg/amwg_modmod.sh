#!/usr/bin/env bash

usage()
{
   echo "Usage: amwg_modmod.sh [-u USERexp] [-r ALT_RUNDIR] EXP1 EXP2 YEAR1 YEAR2"
   echo
   echo "Do an AMWG analysis of experiment EXP1 EXP2 in years YEAR1 to YEAR2"
   echo
   echo "Basically a wrapper around:"
   echo "     ncarize (to create climatology from post-processed EC-Earth output)"
   echo "     diag_mod_vs_mod.sh (the plot engine)"
   echo 
   echo "Option:"
   echo "   -r ALT_RUNDIR : fully qualified path to another user EC-Earth top RUNDIR [NOT TESTED YET!]"
   echo "                that has been  processed by hiresclim2."
   echo "                That means RUNDIR/EXP/post must exists, contain files, and be readable"
   echo "   -u USERexp  : alternative user owner of the experiment, default $USER"
}

ALT_RUNDIR=""
set -ue

# -- options

while getopts "h?u:r:" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        u)  USERexp=$OPTARG
            ;;
        r)  ALT_RUNDIR=$OPTARG 
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$#" -ne 4 ]; then
   usage
   exit 0
fi

EXPID=$1
EXPID2=$2
year1=$3
year2=$4

EXPID=$EXPID

# -- Sanity check
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 


# -- User configuration
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_amwg_${ECE3_POSTPROC_MACHINE}.sh

# - installation params
export EMOP_DIR=$ECE3_POSTPROC_TOPDIR/amwg
export DIR_EXTRA="${EMOP_DIR}/data"

# - HiresClim2 post-processed files loc 
if [[ -n $ALT_RUNDIR ]]
then
    POST_DIR=$ALT_RUNDIR
else
    POST_DIR=$(eval echo ${ECE3_POSTPROC_POSTDIR})
fi

[[ ! -d $POST_DIR ]] && echo "*EE* Experiment output dir $POST_DIR does not exist!" && exit 1
export POST_DIR
echo "$POST_DIR"

# test if it was a coupled run, and find resolution
# TODO use same checks in hiresclim2, ECMean and timeseries
# TODO test with real 2 year data, in my (Etienne) tests with faked 2 year data the plots were very wrong
check=$( ls $POST_DIR/mon/Post_*/*sosaline* 2>/dev/null || true )
NEMOCONFIG=""
do_ocean=0
if [[ -n $check ]]
then
    do_ocean=1

    a_file=$(ls -1 $POST_DIR/mon/Post_*/*sosaline.nc | head -n1)
    ysize=$(cdo griddes $a_file | grep ysize | awk '{print $3}')

    case $ysize in
        1050)
            NEMOCONFIG=ORCA025L75
            ;;
        292)
            NEMOCONFIG=ORCA1L75
            ;;
        *)
            echo '*EE* Unaccounted NEMO resolution: ysize=$ysize' && exit 1
    esac

    export NEMOCONFIG
    echo "*II* ecmean accounts for nemo output"
fi

echo "nemoconf is $NEMOCONFIG"

# where to find mesh and mask files 
export NEMO_MESH_DIR=${MESHDIR_TOP}/$NEMOCONFIG
echo "$NEMO_MESH_DIR"

# -- get to work
if [[ ! -d "$EMOP_CLIM_DIR/clim_${EXPID}_${year1}-${year2}" ]] 
then

  echo "get to work ncarize $EXPID $year1 $year2"
  cd $EMOP_DIR/ncarize
  ./ncarize_pd.sh ${EXPID} ${year1} ${year2}

else
  echo "bye bye $EXPID has already been postprocessed!"
fi

if [[ ! -d "$EMOP_CLIM_DIR/clim_${EXPID2}_${year1}-${year2}" ]] 
then

  echo "get to work ncarize $EXPID2 $year1 $year2"
  cd $EMOP_DIR/ncarize
  ./ncarize_pd.sh ${EXPID2} ${year1} ${year2}

else
  echo "bye bye $EXPID2 has already been postprocessed!"
fi

#  echo "get to work..."
cd $EMOP_DIR/amwg_diag

# use env variables from diag mod vs mod
export TEST_RUN=$EXPID
export CNTL_RUN=$EXPID2
export TEST_PERIOD=${year1}-${year2}
export CNTL_PERIOD=${year1}-${year2}
csh ./csh/diag_mod_vs_mod.csh

# -- Store
DIAGS=$EMOP_CLIM_DIR/diag_${EXPID}_${EXPID2}_${year1}-${year2}
cd $DIAGS
rm -r -f diag_mod_${EXPID}-${EXPID2}.tar
mv ${EXPID}_${year1}-${year2}-mod_${EXPID2}_${year1}-${year2} ${EXPID}-${EXPID2}-mod_${year1}-${year2}   #Ale
tar cvf diag_${EXPID}-${EXPID2}_mod.tar ${EXPID}-${EXPID2}-mod_${year1}-${year2} 
#tar cvf diag_mod_${EXPID}-${EXPID2}.tar ${EXPID}_${year1}-${year2}-mod_${EXPID2}_${year1}-${year2}
ectrans -remote sansone -source diag_${EXPID}-${EXPID2}_mod.tar -verbose -overwrite
ectrans -remote sansone -source ~/EXPERIMENTS.cca.$USER.dat -verbose -overwrite
#ectrans -remote sansone -source ~/EXPERIMENTS.${ECE3_POSTPROC_MACHINE}.$USER.dat -verbose -overwrite
