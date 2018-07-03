#!/bin/bash

# configuration file for nemorebuild script
# add here machine dependent set up

 ######################################
 # Configuration file for NEMO_REBUILD  #
 ######################################

# --- PATTERN TO FIND MODEL OUTPUT
# 
# Must include $EXPID and be single-quoted
#
# optional variable are $USER and  $year
# remove options for alternative user (no need since can be run only by data owner)
export NEMORESULTS='/lus/snx11062/scratch/ms/it/${USER}/ece3/${EXPID}/output/Output_${year}/NEMO'
export TMPDIR='$SCRATCH/tmp/nemo_rbld_${EXPID}_$RANDOM'

# --- TOOLS (required programs, including compression options) -----
if ! module -t list 2>&1 | grep -q nco
then
    module load nco
fi

#scheduler
submit_cmd="qsub"

# required programs
ncrcat="ncrcat"
#rbld="$PERM/ecearth3/revisions/primavera/sources/utils/rebuild_nemo/rebuild_nemo"
rbld="$PERM/ecearth3/revisions/primavera/sources/nemo-3.6/TOOLS/REBUILD_NEMO/rebuild_nemo"

# number of parallel procs for NEMO rebuild
NEMO_NPROCS=4

# ---------- NEMO FILES MANGLING ----------------------

# Files you want to rebuild: grids and frequencies"
export grids="grid_T grid_U grid_V grid_W icemod SBC scalar diaptr"
export freqs="1m 1d 3h"

