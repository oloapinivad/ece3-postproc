#!/bin/bash

set -e

#Script to validate output of ece2cmor3 for a Primavera experiment.
#Uses Jon Seddon's primavera-val python tool.

#Will validate all years between YEAR1 and YEAR2 of experiment with name EXP
EXP=${EXP:-det3}
YEAR1=${YEAR1:-2011}
YEAR2=${YEAR2:-2011}
#YEARS="1956 1957 1971 1974"
#YEARS="1993 2000 2011 2013"


#--------config file-----
config=knl
. ./../config/config_${config}.sh

#####################################################################################################

export PATH="$CONDADIR:$PATH"
export PYTHONPATH=${VALDIR}
source activate validate
VALIDATE=${VALDIR}/bin/validate_data.py

time_start=$(date +%s)
date_start=$(date)

cd $ROOTPATH

echo "=================================================================="
echo "=================================================================="
echo ""
echo "       VALIDATING CMORIZED IFS OUTPUT OF EXPERIMENT ${EXP}"
echo ""
echo "=================================================================="
echo "=================================================================="

function validator { 
	
	year=$1
	cd ${ROOTPATH}/Year_${year}
	checkfile=$ROOTPATH/validate_${year}.txt
        rm -f $checkfile
        nfiles=$(ls | wc -l)
        echo $(pwd)

	${VALIDATE} -l debug .
	
	if [ "$?" = "0" ]; then
		echo "... Year $year, $nfiles files successfully validated!" > $checkfile
		exit 0
	else
		echo "Validation failed for year ${year}!!!" > $checkfile
                exit 1
	fi
	
}

#Looping over years
#for year in $YEARS
for YEAR in $(seq ${YEAR1} ${YEAR2})
do
    echo "=================================================================="
    echo "                      YEAR = ${YEAR}"
    echo "=================================================================="

    validator $YEAR &
    
done
wait
                

            
echo "=================================================================="
echo "            ALL FILES VALIDATED"      
echo "=================================================================="


time_end=$(date +%s)
time_taken=$((time_end - time_start))


echo "Total time taken: ${time_taken} seconds"

source deactivate
exit 0
