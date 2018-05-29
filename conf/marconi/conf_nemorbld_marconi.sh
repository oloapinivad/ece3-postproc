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
# optional variable are $USERexp/$USER, $LEGNB, $year
export ${USERexp:=$USER}
export NEMORESULTS='/marconi_scratch/userexternal/${USERexp}/ece3/${EXPID}/output/Output_${year}/NEMO'

# --- TOOLS (required programs, including compression options) -----

#scheduler
submit_cmd="sbatch"

# required programs
ncrcat="$WORK/opt/bin/ncrcat"
rbld="$WORK/ecearth3/rebuild_nemo/rebuild_nemo"

# number of parallel procs for NEMO rebuild
IFS_NPROCS=1
NEMO_NPROCS=18

# ---------- NEMO FILES MANGLING ----------------------

# Files you want to rebuild: grids and frequencies"
export grids="grid_T grid_U grid_V grid_W icemod SBC scalar"
export freqs="1m 1d 3h"

