#!/bin/bash

# required programs, including compression options
module purge
module_list="intel/pe-xe-2018--binary szip zlib mkl/2018--binary hdf5/1.8.18--intel--pe-xe-2018--binary netcdf/4.6.1--intel--pe-xe-2018--binary python/2.7.12 numpy/1.15.2--python--2.7.12 nco/4.7.8 "
for soft in ${module_list}
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        echo $soft
        module load $soft
    fi
done


# --- PATTERN TO FIND POST-PROCESSED DATA FROM HIRESCLIM2
# 
# Must include ${EXPID} and be single-quoted
#
export ${USERexp:=$USER}
export ECE3_POSTPROC_POSTDIR='/gpfs/scratch/userexternal/${USERexp}/ece3/${EXPID}/post'


# --- TOOLS -----
# Required programs, including compression options
cdo="/galileo/home/userexternal/ffabiano/opt/cdo/cdo"

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
export submit_cmd="sbatch"

#preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"

# --- PROCESSING TO PERFORM (uncomment to change default)
#
# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots or if using the reduced outclass
# ECE3_POSTPROC_ECM_3D_VARS=1
#
# compute clear sky fluxes, set to 0 if using the reduced outclass
# ECE3_POSTPROC_ECM_CLEAR_FLUX=1

# --- OUTPUT -----
#
# [1] Where to save the diagnostics.
#     Can include ${EXPID} and then must be single-quoted.
#     
#     Tables for one simulation will be in ${ECE3_POSTPROC_DIAGDIR}/table/${EXPID}
#     Summary tables for several simulations will be in ${ECE3_POSTPROC_DIAGDIR}/table/
#     
export ECE3_POSTPROC_DIAGDIR='$WORK/$USER/ecearth3/diag'

# [2] Where to save the climatology (769M IFS, 799M IFS+NEMO). 
#
# By default, if this is commented or empty, it is next to hiresclim2 monthly
# means output in the "post" dir:
# 
#     CLIMDIR=${ECE3_POSTPROC_POSTDIR}/clim-${year1}-${year2}
#
# where year1 and year2 are your script argument.
#
#CLIMDIR0=<my favorite path to store climatoloy data>
export CLIMDIR0='/gpfs/scratch/userexternal/${USER}/tmp_ecearth3/ecmean/${EXPID}/post/model2x2_${year1}_${year2}'


# [3] Where to save the extracted PIs for REPRODUCIBILITY tests
#
#     Can include ${STEMID} as ensemble ID.
#     Must be single-quoted if to be evaluated later.
#
export ECE3_POSTPROC_PI4REPRO='$WORK/$USER/ecearth3/diag/${STEMID}'


# About remote HOST to send/install HTML pages to:
export RHOST=wilma.to.isac.cnr.it        ; # remote host to send diagnostic page to///
export RPORT=10133
export RUSER=federico          ; # username associated to remote host (for file export)
export RWWWD=/var/www/html/ecearth/diag/BOTTINO ; # directory of the local or remote host to send the diagnostic page to
