#!/bin/bash

set -e

# Script to validate output of ece2cmor3 for a Primavera experiment.
# Uses Jon Seddon's primavera-val python tool.
# a conda "validate" environment including iris has been installed
# Adapted from Kristina Strommen

#Will validate all years between year1 and year2 of experiment with name expname
expname=${expname:-cccc}
year1=${year1:-1952}
year2=${year2:-1952}

#--------config file-----

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

# load user and machine specifics
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

#####################################################################################################

export PATH="$CONDADIR:$PATH"
export PYTHONPATH=${VALDIR}
source activate validate
VALIDATE=${VALDIR}/bin/validate_data.py

time_start=$(date +%s)
date_start=$(date)

echo "=================================================================="
echo ""
echo "       VALIDATING CMORIZED IFS OUTPUT OF expnameERIMENT ${expname}"
echo ""
echo "=================================================================="
echo "=================================================================="

#Looping over years
for year in $(seq ${year1} ${year2})
do
    	echo "=================================================================="
    	echo "                      year = ${year}"
    	echo "=================================================================="

    	# set directory
	CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
	echo $CMORDIR
    
	cd $CMORDIR
	nfiles=$(ls | wc -l)
	checkfile=../validate_${year}.txt

        #Validate all the (symbolic link) files
	rm -f $checkfile
        ${VALIDATE} -l debug .

        if [ "$?" = "0" ]; then
            echo "...successfully validated month!"
	    echo "... Year $year Month $month, $nfiles files successfully validated!" > $checkfile
        else
            echo "=================================================================="
	    echo "Validation failed for year ${year}!!!" > $checkfile
            exit 1
        fi

	cd ${EASYDIR}

done

                

            
echo "=================================================================="
echo "            ALL FILES SUCCESSFULLY VALIDATED"      
echo "=================================================================="


time_end=$(date +%s)
time_taken=$((time_end - time_start))


echo "Total time taken: ${time_taken} seconds"

source deactivate
exit 0
