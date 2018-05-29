#!/bin/ksh

# IMPORTANT: nco is required installed in $WORK/opt/bin which have been added to our path
# You should install/load the proper module to have nco running if you want to have the timeseries working

module unload cdo hdf5 netcdf python numpy
module load hdf5/1.8.17--intel--pe-xe-2017--binary netcdf/4.4.1--intel--pe-xe-2017--binary cdo python/2.7.12 numpy/1.11.2--python--2.7.12

export ${USERexp:=$USER}
export ECE3_POSTPROC_POSTDIR='/marconi_scratch/userexternal/${USERexp}/ece3/${EXPID}/post'
export MESHDIR_TOP="$WORK/ecearth3/nemo"

# *** EMOP_CLIM_DIR: where to store the AMWG-friendly climatology files:
export EMOP_CLIM_DIR="$SCRATCH/amwg"

# AMWG NCAR data?
export NCAR_DATA="$WORK/ecearth3/amwg_data"
export DATA_OBS="${NCAR_DATA}/obs_data_5.5"

# About web page, on remote server host:
#     =>  set RHOST="" to disable this function...
export RHOST=""
export RUSER=""
export WWW_DIR_ROOT=""

# job scheduler submit command
submit_cmd="sbatch"

############################
# About required software   #
############################

# support for GRIB_API?
# Set the directory where the GRIB_API tools are installed
# Note: cdo had to be compiled with GRIB_API support for this to work
# This is only required if your highest level is above 1 hPa,
# otherwise leave GRIB_API_BIN empty (or just comment the line)!
#export GRIB_API_BIN="/home/john/bin"

# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_BIN="$WORK/opt/bin"

# The scrip "rebuild" as provided with NEMO (relies on flio_rbld.exe):
export RBLD_NEMO="$WORK/ecearth3/rebuild_nemo/rebuild_nemo"

#python
export PYTHON="python"

#cdo
export cdo="cdo"

#convert
export convert="/usr/bin/convert"

# Are the output hiresclim levels "lev" or "plev" ? (older version cdo: lev)
export LEV="plev"    # MARCONI: cdo 1.6.4 (plev) - rhbuild outputs in plev

######################################################
# List of stuffs needed for script NCARIZE_b4_AMWG.sh
######################################################

# In case of coupled simulation, for ocean fields, should we extrapolate
# sea-values over continents for cleaner plots?
#    > will use DROWN routine of SOSIE interpolation package "mask_drown_field.x"

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
