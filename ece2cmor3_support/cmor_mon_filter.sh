#!/bin/bash

##########################################################################
#
# Filter and CMORize one month of IFS output and/or one leg of NEMO
#
# Paolo Davini (Apr 2018) - based on a script by Gijs van Oord and Kristian Strommen
#
#########################################################################

# Required arguments

EXP=${EXP:-qctr}
YEAR=${YEAR:-1950}
MON=${MON:-1}
ATM=${ATM:-1}
OCE=${OCE:-1}
USEREXP=${USEREXP:-imavilia}
NCORES=${NCORES:-1}

# options controller 
OPTIND=1
while getopts ":h:l:m:y:u:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: cmor_mon_filter.sh -e <experiment name> -y <yr> -m <month (1-12)> \
                -a <process atmosphere (0,1): default 1> -o <process ocean (0,1): default 0> -u <userexp>"
          exit 0 ;;
    e)    EXP=$OPTARG ;;
    m)    MON=$OPTARG ;;
    y)    YEAR=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    u)    USEREXP=$OPTARG ;;
    esac
done
shift $((OPTIND-1))

#----program folder definition ------- #

# Location of cmorization tool
SRCDIR=/marconi_work/Pra13_3311/ecearth3/PRIMAVERA/cmorization

#source code of ece2cmor3
ECE2CMOR3DIR=${SRCDIR}/ece2cmor3/ece2cmor3

#Jon Seddon tables
TABDIR=${SRCDIR}/cmip6-cmor-tables/Tables

#locaton of the ece2cmor3_support (this folder)
SCRIPTDIR=$HOME/ecearth3/ece3-postproc/ece2cmor3_support

#---------user configuration ---------#

# Output directory for the cmorized data
#CMORDIR=$SCRATCH/ece3/${EXP}/cmorized/Year_${YEAR}/Month_${MON}
CMORDIR=$SCRATCH/newtest_11apr

# Metadata directory and file
METADATADIR=$SCRIPTDIR/metadata/
METADATAFILE=$METADATADIR/metadata-primavera-${EXP}.json

# Variable list directory and files
VARLISTDIR=$SCRIPTDIR/varlist
cmip6_var=$VARLISTDIR/varlist-cmip6-paolo.json
prim_var=$VARLISTDIR/varlist-primavera-paolo.json
#cmip6_var=$VARLISTDIR/varlist-short.json

# Parameter table directory and files
PARAMDIR=$SCRIPTDIR/paramtable
IFSPAR=$PARAMDIR/ifspar.json
NEMOPAR=$PARAMDIR/nemopar.json
#NEMOPAR=/marconi_work/Pra13_3311/ecearth3/PRIMAVERA/cmorization/ece2cmor3/ece2cmor3/resources


#--------output and tmpdir definition------#

# Location of the experiment output (-u flag)
if [[ $USEREXP != $USER ]] ; then 
   WORKDIR=/marconi_scratch/userexternal/$USEREXP/ece3/${EXP}/output
else
   WORKDIR=/marconi_scratch/userexternal/$USER/ece3/${EXP}/output
fi

# Temporary directories: cmor and linkdata
BASETMPDIR=$SCRATCH/tmp_cmor/${EXP}_${RANDOM}

#-------prelimiary setup------------------#

#clean up modules
module unload hdf5 netcdf cdo netcdff szip zlib python intel

#diagnostics (marconi stuff)
module list
echo $PATH
echo $LD_LIBRARY_PATH

#create folders
mkdir -p $CMORDIR $BASETMPDIR 

#conda activation
export PATH="/marconi/home/userexternal/pdavini0/work/opt/anaconda/bin:$PATH"
source activate ece2cmor3
export PYTHONNOUSERSITE=True
export PYTHONPATH=/marconi_work/Pra13_3311/opt/anaconda/envs/ece2cmor3/lib/python2.7/site-packages
#export HDF5_DISABLE_VERSION_CHECK=1
ece2cmor=$ECE2CMOR3DIR/ece2cmor.py

#----atmosphere cmorization function------#

# Function defining CMORization of IFS output
function runece2cmor_atm {
    PREFIX=$1
    THREADS=$2
    YEAR=$3
    MON=$4

    #define folders
    DATADIR=$WORKDIR/Output_${YEAR}/IFS
    TMPDIR=$BASETMPDIR/atm_${YEAR}_${MON}/$PREFIX
    ATMDIR=$BASETMPDIR/atm_${YEAR}_${MON}/linkdata
    mkdir -p $TMPDIR $ATMDIR

    #to link data from the previous year
    IFSFILE=$DATADIR/ICM??${EXP}+${YEAR}$(printf %02g ${MON})
    if [[ $MON -eq 1 ]] ; then
        YEAR_M1=$((YEAR-1))
        IFSFILE_M1=$WORKDIR/Output_${YEAR_M1}/IFS/ICM??${EXP}+${YEAR_M1}12
    else
        MON_M1=$((MON-1))
        IFSFILE_M1=$WORKDIR/Output_${YEAR}/IFS/ICM??${EXP}+${YEAR}$(printf %02g ${MON_M1})
    fi

    #link all the story
    ln -s $IFSFILE $ATMDIR/
    ln -s $IFSFILE_M1 $ATMDIR/

    #check
    if [ "$ATM" -eq 1 ] && [ ! -d "$DATADIR" ]; then
        echo "Error: data directory $DATADIR for IFS output does not exist, aborting" >&2; exit 1
    fi

    #tables and varlist
    if [ $PREFIX == "CMIP6" ]; then VARLIST=${cmip6_var}; fi
    if [ $PREFIX == "PRIMAVERA" ]; then VARLIST=${prim_var} ; fi

    #check if varlist exists	
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return; fi
    
    #prepare metadata
    CONFIGFILE=$TMPDIR/metadata-${EXP}-year${YEAR}.json
    sed -e 's,<OUTDIR>,'${CMORDIR}',g' $METADATAFILE > $CONFIGFILE

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing filtered IFS data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    $ece2cmor $ATMDIR $YEAR-$(printf %02g $MON)-01 --exp $EXP --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $TMPDIR --ifspar $IFSPAR --tabid $PREFIX --tabdir $TABDIR  --mode append --atm --filter
    
    # Removing tmp directory
    if [ -d "${TMPDIR}" ] ; then
       echo "Deleting temp dir ${TMPDIR}"; rm -rf "${TMPDIR}"
    fi
    
    # Removing linked directory
    if [ -d "${OCEDIR}" ] ; then
        echo "Deleting link dir ${OCEDIR}"; rm -rf "${OCEDIR}"
    fi
   
    #cleanup
    rmdir $BASETMPDIR/atm_${YEAR}_${MON}

    echo "atmospheric ece2cmor3 complete!"

}

#-------oceanic cmorization function---------#

# Function defining CMORization of NEMO output
function runece2cmor_oce {
    PREFIX=$1
    THREADS=$2
    YEAR=$3

    #prepare folder
    DATADIR=$WORKDIR/Output_${YEAR}/NEMO
    TMPDIR=$BASETMPDIR/oce_${YEAR}/$PREFIX
    OCEDIR=$BASETMPDIR/oce_${YEAR}/linkdata
    mkdir -p $TMPDIR $OCEDIR


    #linking
    for t in grid_T grid_U grid_V grid_W icemod scalar SBC ; do
        ln -s $DATADIR/*${t}.nc $OCEDIR/
    done
    
    #check
    if [ "$OCE" -eq 1 ] && [ ! -d "$DATADIR" ] ; then
        echo "Error: data directory $DATADIR for NEMO output does not exist, aborting" >&2; exit 1
    fi
	
    #tables and varlist
    if [ $PREFIX == "CMIP6" ]; then VARLIST=${cmip6_var} ; fi
    if [ $PREFIX == "PRIMAVERA" ]; then VARLIST=${prim_var} ; fi

    #check if varlistb exists   
    if [ ! -f $VARLIST ]; then echo "Skipping non-existent varlist $VARLIST"; return ; fi
	
    #preparing metadata
    CONFIGFILE=$TMPDIR/metadata-${EXP}-year${YEAR}.json
    sed -e 's,<OUTDIR>,'${CMORDIR}',g' $METADATAFILE > $CONFIGFILE

    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing NEMO data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    $ece2cmor $OCEDIR $YEAR-$(printf %02g $MON)-01 --exp $EXP --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $TMPDIR --nemopar $NEMOPAR --tabid $PREFIX --tabdir $TABDIR --mode append --oce    
    
    # Removing tmp directory
    if [ -d "${TMPDIR}" ] ; then
        echo "Deleting temp dir ${TMPDIR}"; rm -rf "${TMPDIR}"
    fi

    # Removing linked directory
    if [ -d "${OCEDIR}" ] ; then
        echo "Deleting link dir ${OCEDIR}"; rm -rf "${OCEDIR}"
    fi
 
    #cleanup
    rmdir $BASETMPDIR/oce_${YEAR}
    
    echo "oceanic ece2cmor3 complete!"

}

#-------real run-----------#

# Running functions
time_start=$(date +%s)
date_start=$(date)
echo "========================================================="
echo "     Processing month ${MON} of year ${YEAR}"

if [ "$OCE" -eq 1 ]; then
    echo "     IFS and NEMO"
else
    echo "     IFS only"
fi

echo "     Time at start: ${date_start}"
echo "========================================================="

# Currently set up to run everything that works!
if [ "$ATM" -eq 1 ]; then
    runece2cmor_atm CMIP6 $NCORES $YEAR $MON
    runece2cmor_atm PRIMAVERA $NCORES $YEAR $MON
fi

if [ "$OCE" -eq 1 ]; then
    runece2cmor_oce CMIP6 $NCORES $YEAR
    #runece2cmor_oce PRIMAVERA $NCORES $YEAR
fi

# Removing linked directory
if [ -d "${BASETMPDIR}" ] ; then
    echo "Cleaning up ${BASETMPDIR}"; rmdir "${BASETMPDIR}"
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
exit 0




