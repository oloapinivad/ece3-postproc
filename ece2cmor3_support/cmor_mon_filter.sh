#!/bin/bash
#
#
##########################################################################
#
# Filter and CMORize one month of IFS output and/or one leg of NEMO
#
# Queue options are currently appropriate for low-res simulations
# A single month of IFS output takes ~40 minutes to process.
# A single leg (=1 year) of NEMO output takes ~15 minutes to process.
#
# Make sure to specify your username, so Python knows where to look
# for the required modules.
#
# KJS (Jan 2018) - based on a script by Gijs van Oord
#
#########################################################################
#
#
#
#SBATCH -A Pra13_3311
#SBATCH -N1 -n36
#SBATCH --partition=bdw_usr_prod
#SBATCH --mem=110GB
#SBATCH --time 03:00:00
#SBATCH --job-name=cmor_mon
#SBATCH --error=outfile_cmor.o%a
#SBATCH --output=outfile_cmor.o%a
#SBATCH --mail-type=ALL


#set -e


# Required arguments

EXP=${EXP:-qsh0}
LEG=${LEG:-000}
STARTYEAR=${STARTYEAR:-2002}
MON=${MON:-1}
ATM=${ATM:-1}
OCE=${OCE:-0}
VERBOSE=${VERBOSE:-1}
USERNAME=${USERNAME:-pdavini0}
USEREXP=${USEREXP:-imavilia}
NCORES=${NCORES:-1}

YEAR=$(( STARTYEAR + $((10#$LEG + 1)) - 1))

OPTIND=1
while getopts ":h:e:l:m:s:v:" OPT; do
    case "$OPT" in
    h|\?) echo "Usage: cmor_mon.sh (-v: verbose) -e <experiment name> -l <leg nr> -s <start yr> -m <month (1-12)> \
                -a <process atmosphere (0,1): default 1> -o <process ocean (0,1): default 0>"
          exit 0 ;;
    e)    EXP=$OPTARG ;;
    l)    LEG=$OPTARG ;;
    m)    MON=$OPTARG ;;
    s)    STARTYEAR=$OPTARG ;;
    a)    ATM=$OPTARG ;;
    o)    OCE=$OPTARG ;;
    v)    VERBOSE=$OPTARG ;;
    u)    USERNAME=$OPTARG ;;
    esac
done
shift $((OPTIND-1))

if [ $VERBOSE == 1 ]; then
    set -x
fi



# Location of ece2cmor.py
#SRCDIR=/marconi_work/Pra13_3311/ecearth3/post/ece2cmor3/ece2cmor3/ece2cmor3
SRCDIR=/marconi_work/Pra13_3311/ecearth3/PRIMAVERA/cmorize/ece2cmor3/ece2cmor3

#locaton of the ece2cmor3_support
SCRIPTDIR=$(pwd) 


# Location of the experiment output.
# It is assumed that IFS output is in $WORKDIR/IFS, and that NEMO output is in $WORKDIR/NEMO (if it exists)
#WORKDIR=$SCRATCH/ece3/${EXP}/output/Output_${YEAR}
if [[ $USEREXP != $USERNAME ]] ; then 
   #WORKDIR=/marconi_scratch/userexternal/$USEREXP/ece3/${EXP}/output/Output_${YEAR}
   WORKDIR=/marconi_scratch/userexternal/$USEREXP/ece3/${EXP}/output
else
   #WORKDIR=/marconi_scratch/userexternal/$USERNAME/ece3/${EXP}/output/Output_${YEAR}
   WORKDIR=/marconi_scratch/userexternal/$USERNAME/ece3/${EXP}/output
fi


# Temporary direc=tory
BASETMPDIR=$SCRATCH/tmp_cmor/${EXP}_${RANDOM}
TMPDIR=$BASETMPDIR/tmp_${YEAR}_${MON}/cmorized
# Where to put filtered data (temporary folder)
FILTDATA=$BASETMPDIR/tmp_${YEAR}_${MON}/filtered

# Output directory for the cmorized data
#CMORDIR=$SCRATCH/ece3/${EXP}/cmorized/Year_${YEAR}/Month_${MON}
#CMORDIR=$SCRATCH/ece3/${EXP}/cmorized/Year_${YEAR}
CMORDIR=$SCRATCH/newtest


# Metadata template file.  
# Should really use different customized file for each experiment type!
#METADATAFILE=$SCRIPTDIR/metadata/metadata-test.json
METADATAFILE=$SCRIPTDIR/metadata/metadata-template.json
#METADATAFILE=$SCRIPTDIR/metadata/metadata-stochastic-amip.json
#METADATAFILE_DEFAULT=$SRCDIR/resources/metadata_templates/metadata-template.json


# Root directory of tables
TABDIR_ROOT=$SRCDIR/resources/tables


# Variable list directory
#VARLISTDIR=$SRCDIR/resources
VARLISTDIR=$SCRIPTDIR/varlist





# Some prelimina1ry setup

module unload hdf5 netcdf
module load hdf5/1.8.17--intel--pe-xe-2017--binary
module load netcdf/4.4.1--intel--pe-xe-2017--binary
module load cdo
source activate ece2cmor3
#export PATH="/marconi/home/userexternal/${USERNAME}/anaconda2/bin:$PATH"
export PYTHONNOUSERSITE=True
export PYTHONPATH=/marconi_work/Pra13_3311/opt/anaconda/envs/ece2cmor3/lib/python2.7/site-packages
export HDF5_DISABLE_VERSION_CHECK=1

ece2cmor=$SRCDIR/ece2cmor.py
#filter=$SRCDIR/filterscripts/filter6h.py
#filter=/marconi_work/Pra13_3311/ecearth3/post/ece2cmor3/ece2cmor3/ece2cmor3/filterscripts/filter6h.py


mkdir -p $CMORDIR
mkdir -p $FILTDATA
mkdir -p $TMPDIR



# Defining filtering function (for separating IFS data in 3hrly and 6hrly components)

function filteroutput {
   
    GGFILE=$WORKDIR/Output_${YEAR}/IFS/ICMGG${EXP}+${YEAR}$(printf %02g ${MON})
    SHFILE=$WORKDIR/Output_${YEAR}/IFS/ICMSH${EXP}+${YEAR}$(printf %02g ${MON})
    
    if [[ $MON -eq 1 ]] ; then 
       	YEAR_M1=$((YEAR-1))
       	GGFILE_M1=$WORKDIR/Output_${YEAR_M1}/IFS/ICMGG${EXP}+${YEAR_M1}12
        SHFILE_M1=$WORKDIR/Output_${YEAR_M1}/IFS/ICMSH${EXP}+${YEAR_M1}12
    else
	MON_M1=$((MON-1))
	GGFILE_M1=$WORKDIR/Output_${YEAR}/IFS/ICMGG${EXP}+${YEAR}$(printf %02g ${MON_M1})
    	SHFILE_M1=$WORKDIR/Output_${YEAR}/IFS/ICMSH${EXP}+${YEAR}$(printf %02g ${MON_M1})
    fi

    echo "Filtering output files ICMGG${EXP}+${YEAR}$(printf %02g ${MON}) and ICMSH${EXP}+${YEAR}$(printf %02g ${MON})"

    $filter -o $FILTDATA -p $GGFILE_M1 $GGFILE
    $filter -o $FILTDATA -p $SHFILE_M1 $SHFILE

    echo "Filtering complete!"
}
    
    
# Function defining CMORization of IFS output

function runece2cmor_atm {
    PREFIX=$1
    THREADS=$2
    YEAR=$3
    MON=$4
    #ATMDIR=$FILTDATA/${FREQARG}hr
    ATMDIR=$FILTDATA

    IFSFILE=$WORKDIR/Output_${YEAR}/IFS/ICM??${EXP}+${YEAR}$(printf %02g ${MON})
    if [[ $MON -eq 1 ]] ; then
        YEAR_M1=$((YEAR-1))
        IFSFILE_M1=$WORKDIR/Output_${YEAR_M1}/IFS/ICM??${EXP}+${YEAR_M1}12
    else
        MON_M1=$((MON-1))
        IFSFILE_M1=$WORKDIR/Output_${YEAR}/IFS/ICM??${EXP}+${YEAR}$(printf %02g ${MON_M1})
    fi
    

    ln -s $IFSFILE $ATMDIR/
    ln -s $IFSFILE_M1 $ATMDIR/


    if [ "$ATM" -eq 1 ] && [ ! -d "$ATMDIR" ]; then
        echo "Error: data directory $ATMDIR for IFS output does not exist, aborting" >&2; exit 1
    fi
    if [ $PREFIX == "CMIP6" ]; then
        VARLIST=$VARLISTDIR/varlist-cmip6.json
	#VARLIST=$VARLISTDIR/varlist-cmip6-paolo.json
    fi
    if [ $PREFIX == "PRIMAVERA" ]; then
        VARLIST=$VARLISTDIR/varlist-prim.json
    fi
    if [ ! -f $VARLIST ]; then
        echo "Skipping non-existent varlist $VARLIST"
        return
    fi
    TMPDIR=$TMPDIR/$PREFIX
    mkdir -p $TMPDIR
   
    BASECONFIG=$METADATAFILE
    sed -e 's,<FREQ>,'${FREQARG}'hr,g' $BASECONFIG > $TMPDIR/temp-leg${LEG}.json
    sed -e 's,<OUTDIR>,'${CMORDIR}',g' $TMPDIR/temp-leg${LEG}.json > $TMPDIR/metadata-${EXP}-leg${LEG}.json
    CONFIGFILE=$TMPDIR/metadata-${EXP}-leg${LEG}.json


    # For choosing only specific tables. Probably it's better to specify a different variable list? Needs testing.
    #TABDIR=${TABDIR_ROOT}/<your table directory>


    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing filtered IFS data with ece2cmor3"
    echo "  Frequency = ${FREQARG}hr"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    #$ece2cmor $ATMDIR $YEAR-$(printf %02g $MON)-01 --exp $EXP --freq $FREQARG --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $TMPDIR --tabid $PREFIX --mode append --atm 
    $ece2cmor $ATMDIR $YEAR-$(printf %02g $MON)-01 --exp $EXP --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $TMPDIR --tabid $PREFIX --mode append --atm --filter
    

    # Removing tmp directory
    if [ -d "${TMPDIR}" ]
    then
        echo "Deleting temp dir ${TMPDIR}" 
        rm -rf "${TMPDIR}"
    fi

    echo "ece2cmor3 complete!"

}



# Function defining CMORization of NEMO output

function runece2cmor_oce {
    FREQARG=$1
    PREFIX=$2
    THREADS=$3
    OCEDIR=$WORKDIR/Output_${YEAR}/NEMO
    if [ "$OCE" -eq 1 ] && [ ! -d "$OCEDIR" ]; then
        echo "Error: data directory $OCEDIR for NEMO output does not exist, aborting" >&2; exit 1
    fi
    if [ $PREFIX == "CMIP6" ]; then
        #VARLIST=$VARLISTDIR/varlist-cmip6.json
	VARLIST=$VARLISTDIR/varlist-paolo-oce.json
    fi
    if [ $PREFIX == "PRIMAVERA" ]; then
        VARLIST=$VARLISTDIR/varlist-prim.json
    fi
    if [ ! -f $VARLIST ]; then
        echo "Skipping non-existent varlist $VARLIST"
        return
    fi

    OCEDIR2=$TMPDIR/DATA
    mkdir -p $OCEDIR2
    echo "Copying rebuild processors data"
    for t in grid_T grid_U grid_V grid_W icemod scalar SBC ; do
	ln -s $OCEDIR/*${t}.nc $OCEDIR2/
    done
    	

    TMPDIR=$TMPDIR/$PREFIX
    mkdir -p $TMPDIR
   
    sed -e 's,<FREQ>,'${FREQARG}'hr,g' $METADATAFILE > $TMPDIR/temp-leg${LEG}.json
    sed -e 's,<OUTDIR>,'${CMORDIR}',g' $TMPDIR/temp-leg${LEG}.json > $TMPDIR/metadata-${EXP}-leg${LEG}.json
    CONFIGFILE=$TMPDIR/metadata-${EXP}-leg${LEG}.json



    # For choosing only specific tables. Perhaps it's better to specificy a different variable list?
    #TABDIR=${TABDIR_ROOT}/${PREFIX}_${FREQARG}hr


    # Launching ece2cmor3
    echo "================================================================"
    echo "  Processing and CMORizing NEMO data with ece2cmor3"
    echo "  Using $PREFIX tables"
    echo "================================================================" 
    $ece2cmor $OCEDIR2 $YEAR-$(printf %02g $MON)-01 --exp $EXP --freq $FREQARG --conf $CONFIGFILE --vars $VARLIST --npp $THREADS --tmpdir $TMPDIR --tabid $PREFIX --mode append --oce    
    

    # Removing tmp directory
    if [ -d "${TMPDIR}" ]
    then
        echo "Deleting temp dir ${TMPDIR}" 
        rm -rf "${TMPDIR}"
    fi

    echo "ece2cmor3 complete!"

}



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
    #filteroutput 
    runece2cmor_atm CMIP6 $NCORES $YEAR $MON
    #runece2cmor_atm 6 CMIP6 $NCORES 
    #runece2cmor_atm 3 PRIMAVERA $NCORES 
    #runece2cmor_atm 6 PRIMAVERA $NCORES  # <-- still some issues with this
fi

if [ "$OCE" -eq 1 ]; then
    runece2cmor_oce 6 CMIP6 $NCORES 
fi





time_end=$(date +%s)
time_taken=$((time_end - time_start))
date_end=$(date)
echo "==========================================================="
echo "     Processing completed!"
echo "     Time at end: ${date_end}"
echo "     Total time taken: ${time_taken} seconds"
echo "==========================================================="



# Removing unprocessed filtered data

echo "Removing unprocessed data..."
if [ -d $"{FILTDATA}" ]
then
    echo "Deleting temp dir ${FILTDATA}"
    rm -rf "${FILTDATA}"
fi




# End of script
echo "Exiting script"
exit 0




