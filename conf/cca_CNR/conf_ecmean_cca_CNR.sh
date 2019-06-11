#!/bin/bash

# --- PATTERN TO FIND POST-PROCESSED DATA FROM HIRESCLIM2
# 
# Must include ${EXPID} and be single-quoted
#
export ${USERexp:=$USER}
[[ -z ${ECE3_POSTPROC_POSTDIR:-} ]] && export ECE3_POSTPROC_POSTDIR='/scratch/ms/it/${USERexp}/ece3/${EXPID}/post'


# --- TOOLS -----
# Required programs, including compression options
module unload cdo
module -s load cdo/1.9.6

export cdo=cdo
export cdozip="$cdo -f nc4c -z zip"
export cdonc="$cdo -f nc"

# job scheduler submit command
submit_cmd="qsub"

# preferred type of CDO interpolation (curvilinear grids are obliged to use bilinear)
export remap="remapcon2"


# --- PROCESS -----
#
# process 3D vars (most of which which are in SH files) ? 
# set to 0 if you only want simple diags e.g. Gregory plots
export do_3d_vars=1


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


[[ -z ${ECE3_POSTPROC_DIAGDIR:-} ]] && export ECE3_POSTPROC_DIAGDIR='$PERM/ecearth3/diag/'

# [2] Where to save the climatology (769M IFS, 799M IFS+NEMO). 
#
# By default, if this is commented or empty, it is next to hiresclim2 monthly
# means output in the "post" dir:
# 
CLIMDIR0='${SCRATCH}/tmp_ecearth3/ECmean/$EXPID/clim-${YEAR1}-${YEAR2}'
#
# where year1 and year2 are your script argument.
#
#CLIMDIR0=<my favorite path to store climatology data>

# [3] Where to save the extracted PIs for REPRODUCIBILITY tests
#
#     Can include ${STEMID} as ensemble ID.
#     Must be single-quoted if to be evaluated later.
#
export ECE3_POSTPROC_PI4REPRO='$PERM/ecearth3/diag/${STEMID}'

# options for ectrans
export do_ectrans=true
export rhost="wilma"

