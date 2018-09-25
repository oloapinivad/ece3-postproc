#!/bin/bash

# simple updater of the cmor code


#--------config file-----
config=marconi
. ./config/config_${config}.sh
#-----------------------

cd $ECE2CMOR3DIR
git fetch
git pull
git submodule update --init --recursive
export PATH="$CONDADIR:$PATH"
source activate ece2cmor3
python setup.py install
source deactivate ece2cmor3
cd -
