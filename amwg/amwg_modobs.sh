#!/usr/bin/env bash

usage()
{
   echo "Usage: amwg_modobs.sh [-u USERexp] [-r ALT_RUNDIR] EXP YEAR1 YEAR2"
   echo
   echo "Do an AMWG analysis of experiment EXP in years YEAR1 to YEAR2"
   echo
   echo "Basically a wrapper around:"
   echo "     ncarize (to create climatology from post-processed EC-Earth output)"
   echo "     diag_mod_vs_obs.sh (the plot engine)"
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

if [ "$#" -ne 3 ]; then
   usage
   exit 0
fi

expname=$1
year1=$2
year2=$3

EXPID=$expname

# -- Sanity check
[[ -z $ECE3_POSTPROC_TOPDIR  ]] && echo "User environment not set. See ../README." && exit 1 
#[[ -z $ECE3_POSTPROC_RUNDIR  ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_DATADIR ]] && echo "User environment not set. See ../README." && exit 1 
[[ -z $ECE3_POSTPROC_MACHINE ]] && echo "User environment not set. See ../README." && exit 1 


# -- User configuration
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_amwg_${ECE3_POSTPROC_MACHINE}.sh

# - installation params
export EMOP_DIR=$ECE3_POSTPROC_TOPDIR/amwg
export DIR_EXTRA="${EMOP_DIR}/data"

# - HiresClim2 post-processed files loc 
if [[ -n $ALT_RUNDIR ]]
then
#    export POST_DIR=$ALT_RUNDIR/mon
    export POST_DIR=$ALT_RUNDIR
else
#    export POST_DIR=$(eval echo ${ECE3_POSTPROC_POSTDIR})/mon
    export POST_DIR=$(eval echo ${ECE3_POSTPROC_POSTDIR})
fi
[[ ! -d $POST_DIR ]] && echo "*EE* Experiment output dir $POST_DIR does not exist!" && exit 1

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
cd $EMOP_DIR/ncarize
./ncarize_pd.sh -C ${ECE3_POSTPROC_MACHINE} -R $expname -i ${year1} -e ${year2}

cd $EMOP_DIR/amwg_diag
./diag_mod_vs_obs.sh -C ${ECE3_POSTPROC_MACHINE} -R $expname -P ${year1}-${year2}


# -- Store
DIAGS=$EMOP_CLIM_DIR/diag_${expname}_${year1}-${year2}
cd $DIAGS
rm -r -f diag_${expname}.tar
tar cvf diag_${expname}.tar ${expname}-obs_${year1}-${year2}
#ectrans -remote sansone -source diag_${expname}.tar -verbose -overwrite
#ectrans -remote sansone -source ~/EXPERIMENTS.${ECE3_POSTPROC_MACHINE}.$USERme.dat -verbose -overwrite
