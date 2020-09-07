#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Based on a script by Gijs van Oord and Kristian Strommen

##########################################################################
#
# Filter and CMORize one year of IFS output and/or one year of NEMO
#
#########################################################################


set -ex
# Required arguments

expname=${expname:-ll00}
year=${year:-2000}
ATM=${ATM:-1}
OCE=${OCE:-0}
VEG=${VEG:-0}
USERexp=${USERexp:-$USER}

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# setting directories 
NEMORESULTS=$(eval echo $NEMORESULTS0)
IFSRESULTS=$(eval echo $IFSRESULTS0)
IFSRESULTS_M1=$(eval echo $IFSRESULTS0_M1)
LPJGRESULTS=$(eval echo $LPJGRESULTS0)
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
RUNDIR=$(eval echo $RUNDIR0)

TMPDIR=$BASETMPDIR/${expname}_${year}_${RANDOM}
mkdir -p $CMORDIR $TMPDIR
echo "Main folders..."
echo "Looking for IFS data in: $IFSRESULTS"
echo "Looking for NEMO data in: $NEMORESULTS"
echo "Putting CMORized data in: $CMORDIR"
echo "Temporary directory is: $TMPDIR"

# bathymetry path for NEMO: use relative path of the experiment
export ECE2CMOR3_NEMO_BATHY_METER=$NEMORESULTS/../../../run/bathy_meter.nc

#---------user configuration ---------#

# configurator
. ${EASYDIR}/config_and_create_metadata.sh $expname

# reference date
REFDATE=${refdate:-1850-01-01}
echo $refdate $REFDATE

# table dir
TABDIR=${tabdir:-}
echo $TABDIR

#-------preliminary setup------------------#

#conda activation
export PATH="$CONDADIR:$PATH"
echo $PATH
source activate ece2cmor3
#export PYTHONNOUSERSITE=True
#export HDF5_DISABLE_VERSION_CHECK=1
ece2cmor=$ECE2CMOR3DIR/ece2cmor.py

#----atmosphere cmorization function------#

# Function defining CMORization of IFS output
function runece2cmor_ifs {
    THREADS=$1
    year=$2

    #define folders
    FLDDIR=$TMPDIR/ifs_${year}/CMIP6
    ATMDIR=$TMPDIR/ifs_${year}/data_${year}
    ATMDIR_M1=$TMPDIR/ifs_${year}/data_$((year - 1))
    mkdir -p $FLDDIR $ATMDIR ${ATMDIR_M1}

    #link all the files
    IFSFILEALL=$IFSRESULTS/ICM??${expname}+${year}??
    ln -s $IFSFILEALL $ATMDIR/

    # link previous year files
    echo ${IFSRESULTS_M1}
    if [[ -d ${IFSRESULTS_M1} ]] ;then 
    	IFSFILEM1=${IFSRESULTS_M1}/ICM??${expname}*12
    	ln -s $IFSFILEM1 ${ATMDIR_M1}/
    else 
	IFSFILEM1SH=${IFSRESULTS}/ICMSH${expname}+000000
	IFSFILEM1GG=${IFSRESULTS}/ICMGG${expname}+000000
	yearm1=$(( year - 1 ))
	ln -s $IFSFILEM1SH ${ATMDIR_M1}/ICMSH${expname}${yearm1}12
	ln -s $IFSFILEM1GG ${ATMDIR_M1}/ICMGG${expname}${yearm1}12
    fi

    # link initial state file 
    ln -s $IFSRESULTS/../../*/IFS/ICM??${expname}+000000 $ATMDIR/

    #check
    if [ "$ATM" -eq 1 ] && [ ! -d "$IFSRESULTS" ]; then
        echo "Error: data directory $IFSRESULTS for IFS output does not exist, aborting" >&2; exit 1
    fi

    #check if varlist exists	
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return; fi
    
    #prepare metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    cp $METADATAFILEATM $CONFIGFILE

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing filtered IFS data with ece2cmor3"
    echo "================================================================" 
    $ece2cmor $ATMDIR --exp $expname --meta $CONFIGFILE --varlist $VARLIST --npp $THREADS --tmpdir $FLDDIR --ifs --odir ${CMORDIR} --overwritemode replace --skip_alevel_vars --refd ${REFDATE} ${TABDIR}

    
    # Removing tmp directory
    if [ -d "${FLDDIR}" ] ; then
       echo "Deleting temp dir ${FLDDIR}"; rm -rf "${FLDDIR}"
    fi
    
    # Removing linked directory
    if [ -d "${ATMDIR}" ] ; then
        echo "Deleting link dir ${ATMDIR}"; rm -rf "${ATMDIR}"
    fi

    # Removing linked directory
    if [ -d "${ATMDIR_M1}" ] ; then
        echo "Deleting link dir ${ATMDIR_M1}"; rm -rf "${ATMDIR_M1}"
    fi
   
    #cleanup
    rmdir $TMPDIR/ifs_${year}

    echo "atmospheric ece2cmor3 complete!"

}

#-------oceanic cmorization function---------#

# Function defining CMORization of NEMO output
function runece2cmor_nemo {
    THREADS=$1
    year=$2

    #prepare folder
    FLDDIR=$TMPDIR/nemo_${year}/CMIP6
    OCEDIR=$TMPDIR/nemo_${year}/data_${year}
    mkdir -p $FLDDIR $OCEDIR

    #linking
    ln -s $NEMORESULTS/${expname}*.nc $OCEDIR/
    cp $RUNDIR/subbasins.nc $BASETMPDIR/
    
    #check
    if [ "$OCE" -eq 1 ] && [ ! -d "$NEMORESULTS" ] ; then
        echo "Error: data directory $NEMORESULTS for NEMO output does not exist, aborting" >&2; exit 1
    fi
	
    #check if varlistb exists   
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return ; fi

    #prepare metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    cp $METADATAFILEOCE $CONFIGFILE
    
    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing NEMO data with ece2cmor3"
    echo "================================================================" 
    $ece2cmor $OCEDIR --exp $expname --meta $CONFIGFILE --varlist $VARLIST --npp $THREADS --tmpdir $FLDDIR --nemo --odir ${CMORDIR} --overwritemode replace --refd ${REFDATE} ${TABDIR}
    
    # Removing tmp directory
    if [ -d "${FLDDIR}" ] ; then
        echo "Deleting temp dir ${FLDDIR}"; rm -rf "${FLDDIR}"
    fi

    # Removing linked directory
    if [ -d "${OCEDIR}" ] ; then
        echo "Deleting link dir ${OCEDIR}"; rm -rf "${OCEDIR}"
    fi
 
    #cleanup
    rmdir $TMPDIR/nemo_${year}
    
    echo "oceanic ece2cmor3 complete!"

}

#-------oceanic cmorization function---------#

# Function defining CMORization of NEMO output
function runece2cmor_lpjg {
    THREADS=$1
    year=$2

    #prepare folder
    FLDDIR=$TMPDIR/lpjg_${year}/CMIP6
    VEGDIR=$TMPDIR/lpjg_${year}/data_${year}
    mkdir -p $FLDDIR $VEGDIR

    #linking
    ln -s $LPJGRESULTS/*.out $VEGDIR/

    #check
    if [ "$VEG" -eq 1 ] && [ ! -d "$LPJGRESULTS" ] ; then
        echo "Error: data directory $LPJGRESULTS for NEMO output does not exist, aborting" >&2; exit 1
    fi

    #check if varlistb exists   
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return ; fi

    #prepare metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    cp $METADATAFILEVEG $CONFIGFILE

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing NEMO data with ece2cmor3"
    echo "================================================================" 
    $ece2cmor $VEGDIR --exp $expname --meta $CONFIGFILE --varlist $VARLIST --npp $THREADS --tmpdir $FLDDIR --lpjg --odir ${CMORDIR} --overwritemode replace --refd ${REFDATE} ${TABDIR}

    # Removing tmp directory
    if [ -d "${FLDDIR}" ] ; then
        echo "Deleting temp dir ${FLDDIR}"; rm -rf "${FLDDIR}"
    fi

    # Removing linked directory
    if [ -d "${VEGDIR}" ] ; then
        echo "Deleting link dir ${OCEDIR}"; rm -rf "${OCEDIR}"
    fi

    #cleanup
    rmdir $TMPDIR/lpjg_${year}

    echo "vegetation ece2cmor3 complete!"

}


#-------real run-----------#

# Running functions
time_start=$(date +%s)
date_start=$(date)
echo "========================================================="
echo "     Processing year ${year}"

if [ "$OCE" -eq 1 ]; then
    echo "     IFS and NEMO"
else
    echo "     IFS only"
fi

echo "     Time at start: ${date_start}"
echo "========================================================="

# Currently set up to run everything that works!
if [ "$ATM" -eq 1 ]; then
    runece2cmor_ifs $NCORESATM $year
fi

if [ "$OCE" -eq 1 ]; then
    runece2cmor_nemo $NCORESOCE $year
fi

if [ "$VEG" -eq 1 ]; then
    runece2cmor_lpjg $NCORESVEG $year
fi

# Removing linked directory
if [ -d "${TMPDIR}" ] ; then
    echo "Cleaning up ${TMPDIR}"; rmdir "${TMPDIR}"
fi

#time for running
time_end=$(date +%s)
time_taken=$((time_end - time_start))
date_end=$(date)
echo "==========================================================="
echo "     Processing completed!"
echo "     Time at end: ${date_end}"
echo "     Total time taken: ${time_taken} seconds"
echo "==========================================================="


# End of script
echo "Exiting script"
conda deactivate
exit 0




