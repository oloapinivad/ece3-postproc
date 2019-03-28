#! /usr/bin/env bash

# wrapper script that call scripts for PI and RK analysis
# firstly interpolate on common 2x2 grid hiresclim outputs
# hence computes RK08 diagnostics and finally produces
# global mean values for radiation and some selected fields

# Paolo Davini (ISAC-CNR) - <p.davini@isac.cnr.it> - December 2014
#   22 May 2017 - Ph. Le Sager

set -ue

usage()
{
    echo "Usage:   ${0##*/} [-y] [-p] [-u USERexp] [-r POSTDIR]  EXP  YEAR_START  YEAR_END"
    echo
    echo "Options are:"
    echo "   -r POSTDIR  : fully qualified path to another dir with Hiresclim2 output."
    echo "                   Must exists and be readable. Default: \${ECE3_POSTPROC_POSTDIR}/mon"
    echo "   -u USERexp  : alternative 'user' owner of the experiment"
    echo "   -y          : (Y)early global mean are added to 'OUTDIR/yearly_fldmean_EXP.txt'"
    echo "   -p          : (P)rimavera specific treatment to select pressure levels"
    echo
    echo "   ECE3_POSTPROC_POSTDIR and USERexp default values should be set in"
    echo "   your conf_timeseries_\$ECE3_POSTPROC_MACHINE.sh file"
}


lp=0
ly=0
ALT_RUNDIR=""

while getopts "h?u:r:py" opt; do
    case "$opt" in
        h|\?)
            usage
            exit 0
            ;;
        r)  ALT_RUNDIR=$OPTARG
	    ;;
	u)  USERexp=$OPTARG
            ;;
        p)  lp=1
            ;;
        y)  ly=1
            ;;
    esac
done
shift $((OPTIND-1))

if [ $# -lt 3 ]
then
    echo; echo "*EE* not enough arguments !!"; echo
    usage
    exit 1
fi

# experiment name
exp=$1
# years to be processed
year1=$2
year2=$3

echo $lp

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment not set. See ../README." && exit 1
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# load cdo, netcdf and dir template for results
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_ecmean_${ECE3_POSTPROC_MACHINE}.sh

# set variables which can be eval'd
EXPID=$exp
export OUTDIR=$(eval echo ${ECE3_POSTPROC_DIAGDIR})/table

TABLEDIR=${OUTDIR}/${exp}
mkdir -p $TABLEDIR

############################################################
# TEMP dirs
############################################################
# Where to store the 2x2 climatologies
echo $(eval echo ${CLIMDIR0-})
[[ -z "${CLIMDIR0:-}" ]] && CLIMDIR=$(eval echo ${ECE3_POSTPROC_POSTDIR})/clim-${year1}-${year2} || CLIMDIR=$(eval echo $CLIMDIR0)
export CLIMDIR
mkdir -p $CLIMDIR

#TMPDIR=$(mktemp -d) # $SCRATCH/tmp_ecearth3_ecmean.XXXXXX)
mkdir -p $SCRATCH/tmp_ecearth3/tmp
export TMPDIR=$(mktemp -d $SCRATCH/tmp_ecearth3/tmp/ecmean_${exp}_XXXXXX)

############################################################
# Checking settings dependent only on the ECE3_POSTPROC_* variables, i.e. env
############################################################
# Where the program is placed
PIDIR=$ECE3_POSTPROC_TOPDIR/ECmean

# Base directory of HiresClim2 postprocessing outputs
if [[ -n $ALT_RUNDIR ]]
then
    export DATADIR=${ALT_RUNDIR}
else
    export DATADIR=$(eval echo ${ECE3_POSTPROC_POSTDIR})/mon
fi
[[ ! -d $DATADIR ]] && echo "*EE* Experiment HiresClim2 output dir $DATADIR does not exist!" && exit 1

# -- nemo
do_ocean=0
[[ -r $DATADIR/Post_${year1}/${exp}_${year1}_sosstsst.nc ]] && do_ocean=1 && \
    echo "*II* ecmean accounts for nemo output"
export do_ocean

# -- other options

# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots or if using the reduced outclass
export do_3d_vars=${ECE3_POSTPROC_ECM_3D_VARS:-1}
# compute clear sky fluxes, set to 0 if using the reduced outclass
export do_clear_flux=${ECE3_POSTPROC_ECM_CLEAR_FLUX:-1}

# -- mask files

# first, find IFS horizontal resolution from one of the processed output
fname=$(ls -1 $DATADIR/Post_$year1/*tas.nc | tail -1)
res=$(cdo griddes $fname | sed -rn "s/ysize.*= ([0-9]+)/\1/p")
(( res-=1 ))

# 2x2 grids for interpolation are included in the Climate_netcdf folder
# (derived from IFS land sea mask). Masks are used by ./global_mean.sh and by
# ./post2x2.sh scripts. They are computed from the original initial conditions
# of IFS (using var 172):
export maskfile=$ECE3_POSTPROC_DATADIR/ifs/T${res}L91/19900101/ICMGGECE3INIT

[[ ! -r $maskfile ]] && echo "*EE* cannot read IFS initial condition: $maskfile" && exit 1

############################################################
# Call postprocessings
############################################################

printf " ----------------------------------- Yearly Global Mean\n"

if [ $ly -eq 1 ]; then
    echo "loopyear switch on: ${ly}"
    [[ ! -e $TABLEDIR/gregory_${exp}.txt ]] && \
        echo "                  net TOA, net Sfc, t2m[tas], SST" > $TABLEDIR/gregory_${exp}.txt
    for iy in $( seq $2 1 $3 ) ; do
        cd $PIDIR/scripts/ 
        ./global_mean.sh $exp $iy $iy
        cd $TABLEDIR/..
        $PIDIR/tab2lin_cs.sh $exp $iy $iy > $TABLEDIR/globtable_cs_${exp}_$iy-$iy.txt
        $PIDIR/tab2lin.sh $exp $iy $iy    > $TABLEDIR/globtable_${exp}_$iy-$iy.txt
        cat $TABLEDIR/globtable_cs_${exp}_$iy-$iy.txt >> $TABLEDIR/yearly_fldmean_${exp}.txt
        rm -f $TABLEDIR/globtable_cs_${exp}_$iy-$iy.txt $TABLEDIR/globtable_${exp}_$iy-$iy.txt
        $PIDIR/gregory.sh $exp $iy $iy >> $TABLEDIR/gregory_${exp}.txt        
    done
fi

cd $PIDIR/scripts/ 

printf "\n\n ----------------------------------- Post 2x2\n"
./post2x2.sh $exp $year1 $year2
set -x

if  (( do_3d_vars ))
then

    printf "\n\n ----------------------------------- old PI2\n"
    ./oldPI2.sh $exp $year1 $year2 $lp

    printf "\n\n----------------------------------- PI3\n"
    ./PI3.sh $exp $year1 $year2 $lp

    # Rearranging in a single table the PI from the old and the new versions
    cat $TABLEDIR/PIold_RK08_${exp}_${year1}_${year2}.txt $TABLEDIR/PI2_RK08_${exp}_${year1}_${year2}.txt > $TMPDIR/out.txt
    rm $TABLEDIR/PI2_RK08_${exp}_${year1}_${year2}.txt $TABLEDIR/PIold_RK08_${exp}_${year1}_${year2}.txt
    mv $TMPDIR/out.txt $TABLEDIR/PI2_RK08_${exp}_${year1}_${year2}.txt 
    
    # rm -rf $TMPDIR
fi

printf "\n\n----------------------------------- Global Mean\n"
./global_mean.sh $exp $year1 $year2

# TODO - avoid interceding update of these 3 files in case of parallel runs
cd $TABLEDIR/..

# produce tables
[[ ! -e globtable.txt ]] && \
    echo "                | TOAnet SW | TOAnet LW | Net TOA | Sfc Net SW | Sfc Net LW | SH Fl. | LH Fl. | SWCF | LWCF | NetSfc* | TOA-SFC | t2m | TCC | LCC | MCC | HCC | TP | P-E |" >> globtable.txt
[[ ! -e globtable_cs.txt ]] && \
    echo '"               " "TOAnet SW" "TOAnet LW" "Net TOA" "Sfc Net SW" "Sfc Net LW" "SH Fl." "LH Fl." "SWCF" "LWCF" "NetSfc*" "TOA-SFC" "t2m" "TCC" "LCC" "MCC" "HCC" "TP" "P-E"' >> globtable_cs.txt
cat globtable.txt globtable_cs.txt

$PIDIR/tab2lin_cs.sh $exp $year1 $year2 >> ./globtable_cs.txt
$PIDIR/tab2lin.sh $exp $year1 $year2 >> ./globtable.txt

[[ ! -e gregory.txt ]] && \
    echo "                  net TOA, net Sfc, t2m[tas], SST" > gregory.txt
$PIDIR/gregory.sh $exp $year1 $year2 >> ./gregory.txt
cat ./gregory.txt

# finalizing
cd -
echo "table produced"

cd $TABLEDIR/..
\rm -f ecmean_$exp.tar 
\rm -f ecmean_$exp.tar.gz
tar cvf ecmean_$exp.tar $exp
gzip ecmean_$exp.tar

#TODO ectrans -remote sansone -source ecmean_$exp.tar.gz  -verbose -overwrite
#TODO ectrans -remote sansone -source ~/EXPERIMENTS.${ECE3_POSTPROC_MACHINE}.$USERme.dat -verbose -overwrite
