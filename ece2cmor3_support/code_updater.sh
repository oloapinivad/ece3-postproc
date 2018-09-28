#!/bin/bash

# simple updater of the cmor code


#--------config file-----
config=cca
. ./config/config_${config}.sh
branch=primavera-stream2
#branch=master
#-----------------------

cd $SRCDIR/ece2cmor3
git checkout $branch
git fetch
git pull
git submodule update --init --recursive
export PATH="$CONDADIR:$PATH"
echo $PATH
source activate ece2cmor3
python setup.py install
source deactivate ece2cmor3
cd -
