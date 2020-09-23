#!/bin/bash


# --- TOOLS -----
# Required programs, including compression options

# IMPORTANT: nco is required installed in $WORK/opt/bin which have been added to our path
# You should install/load the proper module to have nco running if you want to have the timeseries working

# required programs, including compression options
#module purge

#export PATH="/galileo/home/userexternal/ffabiano/opts/miniconda3/bin:$PATH"
#source /galileo/home/userexternal/ffabiano/opts/miniconda3/etc/profile.d/conda.sh
#conda activate py2
export PATH=/galileo/home/userexternal/ffabiano/opts/miniconda3/envs/py2/bin:${PATH}

#module_list="intel/pe-xe-2018--binary szip zlib mkl/2018--binary hdf5/1.8.18--intel--pe-xe-2018--binary netcdf/4.6.1--intel--pe-xe-2018--binary python/2.7.12 numpy/1.15.2--python--2.7.12 nco"
#for soft in ${module_list}
#do
#    if ! module -t list 2>&1 | grep -q $soft
#    then
#        echo $soft
#        module load $soft
#    fi
#done

export ${USERexp:=$USER}
export ECE3_POSTPROC_DIAGDIR='$WORK/ffabiano/ecearth3/diag'
export ECE3_POSTPROC_POSTDIR='/gpfs/scratch/userexternal/${USERexp}/ece3/${EXPID}/post'
export MESHDIR_TOP="$WORK/ffabiano/ecearth3/ece3-postproc-files"

# The CDFTOOLS set of executables should be found into:
export CDFTOOLS_BIN="$WORK/ffabiano/ecearth3/cdftools4/bin"

# The scrip "rebuild" as provided with NEMO (relies on flio_rbld.exe):
export RBLD_NEMO="$WORK/ecearth3/rebuild_nemo/rebuild_nemo"

#python
export PYTHON="python"

# job scheduler submit command
export submit_cmd="sbatch"

# About remote HOST to send/install HTML pages to:
export RHOST=wilma.to.isac.cnr.it        ; # remote host to send diagnostic page to///
export RPORT=10133
export RUSER=federico          ; # username associated to remote host (for file export)
export RWWWD=/var/www/html/ecearth/diag/BOTTINO ; # directory of the local or remote host to send the diagnostic page to

