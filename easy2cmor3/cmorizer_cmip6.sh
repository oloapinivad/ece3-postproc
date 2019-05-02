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

expname=${expname:-cj02}
year=${year:-1851}
ATM=${ATM:-1}
OCE=${OCE:-0}
USERexp=${USERexp:-ccjh}
DO_CMIP6=${DO_CMIP6:-true} #flag for CMIP6 tables

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# setting directories 
NEMORESULTS=$(eval echo $NEMORESULTS0)
IFSRESULTS=$(eval echo $IFSRESULTS0)
IFSRESULTS_M1=$(eval echo $IFSRESULTS0_M1)
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})

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

# Metadata directory and file
METADATADIR=${EASYDIR}/metadata
METADATAFILEATM=${METADATADIR}/cmip6-CMIP-piControl-metadata-template.json
METADATAFILEOCE=${METADATADIR}/cmip6-CMIP-piControl-metadata-template.json

# Variable list directory and files
VARLISTDIR=$EASYDIR/varlist
cmip6_var=$VARLISTDIR/cmip6-data-request-varlist-CMIP-historical-EC-EARTH-AOGCM.json

# Parameter table directory and files - USE DEFAULT
#PARAMDIR=$EASYDIR/paramtable
#PARAMDIR=$ECE2CMOR3DIR/resources
#IFSPAR=$PARAMDIR/ifspar-stream2.json
#NEMOPAR=$PARAMDIR/nemopar-stream2.json


#-------preliminary setup------------------#

#conda activation
export PATH="$CONDADIR:$PATH"
echo $PATH
source activate ece2cmor3
export PYTHONNOUSERSITE=True
#export HDF5_DISABLE_VERSION_CHECK=1
ece2cmor=$ECE2CMOR3DIR/ece2cmor.py

#----atmosphere cmorization function------#

# Function defining CMORization of IFS output
function runece2cmor_ifs {
    PREFIX=$1
    THREADS=$2
    year=$3

    #define folders
    FLDDIR=$TMPDIR/ifs_${year}/$PREFIX
    ATMDIR=$TMPDIR/ifs_${year}/data_${year}
    ATMDIR_M1=$TMPDIR/ifs_${year}/data_$((year - 1))
    mkdir -p $FLDDIR $ATMDIR ${ATMDIR_M1}

    #link all the files
    IFSFILEALL=$IFSRESULTS/ICM??${expname}*
    ln -s $IFSFILEALL $ATMDIR/

    # link previous year files
    echo ${IFSRESULTS_M1}
    if [[ -d ${IFSRESULTS_M1} ]] ;then 
    	IFSFILEM1=${IFSRESULTS_M1}/ICM??${expname}*12
    	ln -s $IFSFILEM1 ${ATMDIR_M1}/
    fi

    # link initial state file 
    ln -s $IFSRESULTS/../../*/IFS/*000000 $ATMDIR/

    #check
    if [ "$ATM" -eq 1 ] && [ ! -d "$IFSRESULTS" ]; then
        echo "Error: data directory $IFSRESULTS for IFS output does not exist, aborting" >&2; exit 1
    fi

    #tables and varlist
    if [ $PREFIX == "CMIP6" ]; then VARLIST=${cmip6_var}; fi

    #check if varlist exists	
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return; fi
    
    #prepare metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    cp $METADATAFILEATM $CONFIGFILE

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing filtered IFS data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    $ece2cmor $ATMDIR --exp $expname --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $FLDDIR --ifs --odir ${CMORDIR} --overwritemode replace --skip_alevel_vars
    
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
    PREFIX=$1
    THREADS=$2
    year=$3

    #prepare folder
    FLDDIR=$TMPDIR/nemo_${year}/$PREFIX
    OCEDIR=$TMPDIR/nemo_${year}/data_${year}
    mkdir -p $FLDDIR $OCEDIR

    #linking
    ln -s $NEMORESULTS/${expname}*.nc $OCEDIR/
    
    #check
    if [ "$OCE" -eq 1 ] && [ ! -d "$NEMORESULTS" ] ; then
        echo "Error: data directory $NEMORESULTS for NEMO output does not exist, aborting" >&2; exit 1
    fi
	
    #tables and varlist
    if [ $PREFIX == "CMIP6" ]; then VARLIST=${cmip6_var} ; fi

    #check if varlistb exists   
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return ; fi

    #prepare metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    cp $METADATAFILEATM $CONFIGFILE
	

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing NEMO data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    $ece2cmor $OCEDIR --exp $expname --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $FLDDIR --nemo --odir ${CMORDIR} --overwritemode replace
    
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
    if ${DO_CMIP6} ; then runece2cmor_ifs CMIP6 $NCORESATM $year ; fi
fi

if [ "$OCE" -eq 1 ]; then
    if ${DO_CMIP6} ; then runece2cmor_nemo CMIP6 $NCORESOCE $year ; fi
fi

if [ "$VEG" -eq 1 ]; then
    if ${DO_CMIP6} ; then runece2cmor_lpjg CMIP6 $NCORESVEG $year ; fi
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
conda deactivate ece2cmor3
exit 0




