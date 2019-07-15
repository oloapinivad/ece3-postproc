#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (Oct 2018)

# simple updater of the cmor code
# the branch to be installed can be specified


#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# to checkout a different branch
branch=${1:-master}

# to do a forced cleanup and reinstall
hard=false
#-----------------------

# go to the code directory and download the latest version of the code
cd $SRCDIR/ece2cmor3
git checkout $branch
git fetch
git pull
git submodule update --init --recursive

# activate conda
export PATH="$CONDADIR:$PATH"
echo $PATH

# option for forced clean up, update and reinstall
if [[ $hard == true ]] ; then
   echo "HARD CLEANUP"
   #echo "update conda..."
   #conda update -n base conda
   echo "remove environment..."
   conda-env remove -y -n ece2cmor3
   echo "create environment..."
   conda env create -f environment.yml
fi

# activate env, install
source activate ece2cmor3
python setup.py install

# test
ece2cmor -h

# close and back home
conda deactivate
cd ${EASYDIR}
