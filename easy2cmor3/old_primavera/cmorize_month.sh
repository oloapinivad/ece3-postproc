#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Based on a script by Gijs van Oord and Kristian Strommen

##########################################################################
#
# Filter and CMORize one month of IFS output and/or one year of NEMO
#
#########################################################################

set -ex
# Required arguments

expname=${expname:-cj02}
year=${year:-1850}
MON=${MON:-1}
ATM=${ATM:-1}
OCE=${OCE:-0}
USERexp=${USERexp:-ccjh}
NCORESATM=${NCORESATM:-1}
NCORESOCE=${NCORESOCE:-1}
STARTTIME=${STARTTIME:-1850-01-01}
DO_CMIP6=${DO_CMIP6:-true} #flag for CMIP6 tables
DO_PRIMA=${DO_PRIMA:-false} #extra flag for PRIMAVERA tables

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# setting directories 
NEMORESULTS=$(eval echo $NEMORESULTS0)
IFSRESULTS=$(eval echo $IFSRESULTS0)
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})

TMPDIR=$BASETMPDIR/${expname}_${year}_${RANDOM}
mkdir -p $CMORDIR $TMPDIR

echo "Main folders..."
echo "Looking for IFS data in: $IFSRESULTS"
echo "Looking for NEMO data in: $NEMORESULTS"
echo "Putting CMORized data in: $CMORDIR"
echo "Temporary directory is: $TMPDIR"

#---------user configuration ---------#

# Metadata directory and file
METADATADIR=${EASYDIR}/metadata
METADATAFILEATM=${METADATADIR}/cmip6-CMIP-piControl-metadata-template.json
METADATAFILEOCE=${METADATADIR}/cmip6-CMIP-piControl-metadata-template.json

#METADATAFILEATM=${METADATADIR}/metadata-primavera-${expname}-atm.json
#METADATAFILEOCE=${METADATADIR}/metadata-primavera-${expname}-oce.json

# Variable list directory and files
VARLISTDIR=$EASYDIR/varlist
cmip6_var=$VARLISTDIR/cmip6-data-request-varlist-CMIP-historical-EC-EARTH-AOGCM.json


#cmip6_var=$VARLISTDIR/varlist-cmip6-stream2.json
#prim_var=$VARLISTDIR/varlist-primavera-stream2.json
#cmip6_var=$VARLISTDIR/varlist-short.json
#prim_var=$VARLISTDIR/varlist-primavera-short.json

# Parameter table directory and files
#PARAMDIR=$EASYDIR/paramtable
#PARAMDIR=$ECE2CMOR3DIR/resources
#IFSPAR=$PARAMDIR/ifspar-stream2.json
#NEMOPAR=$PARAMDIR/nemopar-stream2.json


#-------preliminary setup------------------#

#clean up modules

#conda activation
export PATH="$CONDADIR:$PATH"
echo $PATH
source activate ece2cmor3
export PYTHONNOUSERSITE=True
#export HDF5_DISABLE_VERSION_CHECK=1
ece2cmor=$ECE2CMOR3DIR/ece2cmor.py

#----atmosphere cmorization function------#

# Function defining CMORization of IFS output
function runece2cmor_atm {
    PREFIX=$1
    THREADS=$2
    year=$3
    MON=$4

    #define folders
    FLDDIR=$TMPDIR/atm_${year}_${MON}/$PREFIX
    ATMDIR=$TMPDIR/atm_${year}_${MON}/linkdata
    mkdir -p $FLDDIR $ATMDIR

    #to link data from the previous year
 #   IFSFILE=$IFSRESULTS/ICM??${expname}+${year}$(printf %02g ${MON})
 #   if [[ $MON -eq 1 ]] ; then
 #       year_M1=$((year-1))
#	IFSRESULTS_M1=$(echo $IFSRESULTS | sed -r "s/${year}/${year_M1}/g")
    #    IFSFILE_M1=${IFSRESULTS_M1}/ICM??${expname}+${year_M1}12
    #else
    #    MON_M1=$((MON-1))
    #    IFSFILE_M1=$IFSRESULTS/ICM??${expname}+${year}$(printf %02g ${MON_M1})
    #fi

    #link all the story
    IFSFILEALL=$IFSRESULTS/ICM??${expname}+${year}*
    ln -s $IFSFILEALL $ATMDIR/
    #ln -s $IFSFILE_M1 $ATMDIR/

    #check
    if [ "$ATM" -eq 1 ] && [ ! -d "$IFSRESULTS" ]; then
        echo "Error: data directory $IFSRESULTS for IFS output does not exist, aborting" >&2; exit 1
    fi

    #tables and varlist
    if [ $PREFIX == "CMIP6" ]; then VARLIST=${cmip6_var}; fi
    if [ $PREFIX == "PRIMAVERA" ]; then VARLIST=${prim_var} ; fi

    #check if varlist exists	
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return; fi
    
    #prepare metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    #sed -s 's,<OUTDIR>,'${CMORDIR}',g' $METADATAFILEATM > $CONFIGFILE
    #sed -i 's,<INDEX>,'${INDEX}',g' $CONFIGFILE
    cp $METADATAFILEATM $CONFIGFILE

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing filtered IFS data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    #$ece2cmor $ATMDIR $year-$(printf %02g $MON)-01 --exp $expname --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $FLDDIR --ifspar $IFSPAR --tabid $PREFIX --tabdir $TABDIR  --mode append --atm --refd $STARTTIME
    $ece2cmor $ATMDIR --exp $expname --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $FLDDIR --ifs --refd $STARTTIME --odir ${CMORDIR}
    
    # Removing tmp directory
    if [ -d "${FLDDIR}" ] ; then
       echo "Deleting temp dir ${FLDDIR}"; rm -rf "${FLDDIR}"
    fi
    
    # Removing linked directory
    if [ -d "${ATMDIR}" ] ; then
        echo "Deleting link dir ${ATMDIR}"; rm -rf "${ATMDIR}"
    fi
   
    #cleanup
    rmdir $TMPDIR/atm_${year}_${MON}

    echo "atmospheric ece2cmor3 complete!"

}

#-------oceanic cmorization function---------#

# Function defining CMORization of NEMO output
function runece2cmor_oce {
    PREFIX=$1
    THREADS=$2
    year=$3

    #prepare folder
    FLDDIR=$TMPDIR/oce_${year}/$PREFIX
    OCEDIR=$TMPDIR/oce_${year}/linkdata
    mkdir -p $FLDDIR $OCEDIR


    #linking
    for t in grid_T grid_U grid_V grid_W icemod scalar SBC ; do
        ln -s $NEMORESULTS/*${t}.nc $OCEDIR/
    done
    
    #check
    if [ "$OCE" -eq 1 ] && [ ! -d "$NEMORESULTS" ] ; then
        echo "Error: data directory $NEMORESULTS for NEMO output does not exist, aborting" >&2; exit 1
    fi
	
    #tables and varlist
    if [ $PREFIX == "CMIP6" ]; then VARLIST=${cmip6_var} ; fi
    if [ $PREFIX == "PRIMAVERA" ]; then VARLIST=${prim_var} ; fi

    #check if varlistb exists   
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return ; fi
	
    #preparing metadata
    CONFIGFILE=$FLDDIR/metadata-${expname}-year${year}.json
    sed -s 's,<OUTDIR>,'${CMORDIR}',g' $METADATAFILEOCE > $CONFIGFILE
    #sed -i 's,<INDEX>,'${INDEX}',g' $CONFIGFILE 

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing NEMO data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    $ece2cmor $OCEDIR $year-$(printf %02g $MON)-01 --exp $expname --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $FLDDIR --nemopar $NEMOPAR --tabid $PREFIX --tabdir $TABDIR --mode append --oce    
    
    # Removing tmp directory
    if [ -d "${FLDDIR}" ] ; then
        echo "Deleting temp dir ${FLDDIR}"; rm -rf "${FLDDIR}"
    fi

    # Removing linked directory
    if [ -d "${OCEDIR}" ] ; then
        echo "Deleting link dir ${OCEDIR}"; rm -rf "${OCEDIR}"
    fi
 
    #cleanup
    rmdir $TMPDIR/oce_${year}
    
    echo "oceanic ece2cmor3 complete!"

}

#-------real run-----------#

# Running functions
time_start=$(date +%s)
date_start=$(date)
echo "========================================================="
echo "     Processing month ${MON} of year ${year}"

if [ "$OCE" -eq 1 ]; then
    echo "     IFS and NEMO"
else
    echo "     IFS only"
fi

echo "     Time at start: ${date_start}"
echo "========================================================="

# Currently set up to run everything that works!
if [ "$ATM" -eq 1 ]; then
    if ${DO_CMIP6} ; then runece2cmor_atm CMIP6 $NCORESATM $year $MON ; fi
    if ${DO_PRIMA} ; then runece2cmor_atm PRIMAVERA $NCORESATM $year $MON ; fi
fi

if [ "$OCE" -eq 1 ]; then
    if ${DO_CMIP6} ; then runece2cmor_oce CMIP6 $NCORESOCE $year ; fi
    if ${DO_PRIMA} ; then runece2cmor_oce PRIMAVERA $NCORESOCE $year ; fi
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
source deactivate
exit 0




