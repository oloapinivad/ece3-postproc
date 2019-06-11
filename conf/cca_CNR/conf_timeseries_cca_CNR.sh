#!/usr/bin/env bash

#############################################
# Configuration file for timeseries script  #
#############################################

# --- INPUT -----
#
# Where to find monthly averages from hireclim (i.e. data are in $ECE3_POSTPROC_POSTDIR/mon)
# 
# Token ${USERexp} can be used (and set through -u option at the command line).
# Provide default if using it. 
#
export ${USERexp:=$USER} 
[[ -z ${ECE3_POSTPROC_POSTDIR:-} ]] && export ECE3_POSTPROC_POSTDIR='/scratch/ms/it/${USERexp}/ece3/${EXPID}/post'
#
# Where to find mesh and mask files for NEMO.
# Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="/perm/ms/it/ccpd/ecearth3/ece3-postproc-files"

# --- OUTPUT -----
#
# [1] # Where to store time-series plots
#     Can include ${EXPID} and then must be single-quoted.
#     
#     Timeseries for one simulation will be in ${ECE3_POSTPROC_DIAGDIR}/timeseries/${EXPID}
#     available in two netCDF files and two html pages (one for atmosphere and one for ocean)
#     
#     (See also ./conf_ecmean_rhino.sh for a similar 'diagdir')
#     
[[ -z ${ECE3_POSTPROC_DIAGDIR:-} ]] && export ECE3_POSTPROC_DIAGDIR='$PERM/ecearth3/diag/'
#
#  [2] The output can be put on a remote machine RHOST (login: RUSER)
#      in the WWW_DIR_ROOT/time_series/${EXPID} directory, using ssh and scp.
#       =>  Comment or set RHOST="" to disable this function...
#export RHOST=pc170547
export RUSER=""
export WWW_DIR_ROOT=""

# options for ectrans
export do_ectrans=true
export rhost="wilma"


#######################
# Required software   #
#######################

module unload nco cdo python

for soft in nco/4.6.7 netcdf python/2.7.12-01 cdo/1.9.6
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

# The CDFTOOLS set of executables should be found into:
#export CDFTOOLS_BIN="${CDFTOOLS_DIR}/bin"

# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="${PERM}/ecearth3/revisions/ecearth-3.3.1/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

export PYTHON=python
export cdo=cdo

# job scheduler submit command
submit_cmd="qsub"

