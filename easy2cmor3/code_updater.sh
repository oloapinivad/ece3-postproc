#!/bin/bash

# simple updater of the cmor code


#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
branch=${1:-master}
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
cd ${EASYDIR}
