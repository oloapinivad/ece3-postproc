#!/bin/bash

#simple updater of the cmor code
CODEDIR=/marconi/home/userexternal/pdavini0/work/ecearth3/cmorization

module unload netcdf netcdff hdf5 cdo
cd $CODEDIR/ece2cmor3
git fetch
git pull
git submodule update --init --recursive
export PATH="/marconi/home/userexternal/pdavini0/work/opt/anaconda2/bin:$PATH"
source activate ece2cmor3
python setup.py install
source deactivate ece2cmor3
cd -
