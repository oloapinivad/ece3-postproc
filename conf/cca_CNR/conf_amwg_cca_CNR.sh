#!/usr/bin/env bash

 ######################################
 #     Configuration file for AMWG    #
 ######################################

export ${USERexp:=$USER}
export ECE3_POSTPROC_POSTDIR='/scratch/ms/it/${USERexp}/ece3/${EXPID}/post'

# where to find mesh and mask files for NEMO. Files are expected in $MESHDIR_TOP/$NEMOCONFIG.
export MESHDIR_TOP="$PERM/ecearth3/nemo"

#########################

# Root path to a temporary filesystem:
export TMPDIR_ROOT=$SCRATCH/tmp_ecearth/amwg

# *** EMOP_CLIM_DIR: where to store the AMWG-friendly climatology files:
export EMOP_CLIM_DIR=$SCRATCH/amwg

# Where to store time-series produced by script
export DIR_TIME_SERIES="${EMOP_CLIM_DIR}/timeseries"

# AMWG NCAR data? Use Jost's copy for now
export NCAR_DATA=/perm/ms/it/ccjh/ecearth3/amwg_data
export DATA_OBS="${NCAR_DATA}/obs_data_5.5"

# --- TOOLS (required programs, including compression options) -----
submit_cmd="qsub"
queue_cmd="qstat -u $USER"

module unload ncl     #unload ncl 6.4.0 (>>> WARNINGS)

for soft in netcdf4 cdo ncl/6.2.0 nco python cdftools
do
    if ! module -t list 2>&1 | grep -q $soft
    then
        module load $soft
    fi
done

# support for GRIB_API?
# Set the directory where the GRIB_API tools are installed
# Note: cdo had to be compiled with GRIB_API support for this to work
# This is only required if your highest level is above 1 hPa,
# otherwise leave GRIB_API_BIN empty (or just comment the line)!
#export GRIB_API_BIN="/home/john/bin"

export CDFTOOLS_BIN="${CDFTOOLS_DIR}/bin"

# The rebuild_nemo (provided with NEMO), that somebody has built (relies on flio_rbld.exe):
export RBLD_NEMO="${PERM}/ecearth3/revisions/trunk/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

export PYTHON=python
export cdo=cdo
export convert=convert

# Are the output hiresclim levels "lev" or "plev" ? (older cdo version: "lev"; new cdo version: "plev")
# Set LEV on cdo version which you are using.
export LEV="plev"   # rhbuild outputs in plev
                    # CCA: default cdo version 1.8.2 (plev)

# About web page, on remote server host:
#     =>  set RHOST="" to disable this function...
export RHOST=""
export RUSER=""
export WWW_DIR_ROOT=""


######################################################
# List of stuffs needed for script NCARIZE_b4_AMWG.sh
######################################################

# In case of coupled simulation, for ocean fields, should we extrapolate
# sea-values over continents for cleaner plots?
#    > will use DROWN routine of SOSIE interpolation package "mask_drown_field.x"
#i_drown_ocean_fields 1 ; # 1  > do it / 0  > don't

export i_drown_ocean_fields="1" ; # 1  > do it / 0  > don't
export MESH_MASK_ORCA="mask.nc"


# Ocean fields:
export LIST_V_2D_OCE="sosstsst iiceconc"


# 2D Atmosphere fields (ideally):
#export LIST_V_2D_ATM="ps \
               #msl \
               #uas \
               #vas \
               #tas \
               #e stl1 \
               #tcc totp cp lsp ewss nsss sshf slhf ssrd strd \
               #ssr str tsr ttr tsrc ttrc ssrc strc lcc mcc hcc \
               #tcwv tclw tciw fal"
#
# Those we have:
export LIST_V_2D_ATM="msl uas vas tas e sp \
                tcc totp cp lsp ewss nsss sshf slhf ssrd strd \
                ssr str tsr ttr tsrc ttrc ssrc strc lcc mcc hcc \
                tcwv tclw tciw fal"


# 3D Atmosphere fields (ideally):
export LIST_V_3D_ATM="q r t u v z"

# Those we have:
#export LIST_V_3D_ATM="q t u v z"

