#!/bin/bash

set -e

#Script to validate output of ece2cmor3 for a Primavera experiment.
#Uses Jon Seddon's primavera-val python tool.

#Will validate all year for expname
expname=${expname:-qctr}
year=${year:-1963}


#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

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
echo "       VALIDATING CMORIZED IFS OUTPUT OF expnameERIMENT ${expname}"
echo ""
echo "=================================================================="
echo "=================================================================="

function validator {
	file=$1
	echo $file
	${VALIDATE} -l debug -s $file
	if [ "$?" = "0" ] ; then
		echo "$file" >> $tmpfile
	fi
}

echo "=================================================================="
echo "                      year = ${year}"
echo "=================================================================="

CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
echo $CMORDIR
cd $CMORDIR
checkfile=../validate_${year}.txt
tmpfile=../tmp${year}.txt
rm -f $tmpfile
rm -f $checkfile
files=$(ls -S)
nfiles=$(ls | wc -l)
for file in $files ; do
	ll=$(ls -lS $file | cut -f5 -d" ")
	#echo $file
        nn=$((nn + ll ))
	kk=$((kk + 1 ))
	if [[ nn -ge 39000000000 ]] ; then
		echo "Loaded $(( kk - 1 )) files..."
		echo "File loaded reaching... $(( nn - ll ))" 
                wait
                echo "New Loop!"
		nn=$ll
		kk=1
        fi

	validator $file &
done
wait

tt=$(cat ../tmp${year}.txt | wc -l )
if [[ $tt -eq $nfiles ]] ; then 
	echo "... Year $year, $nfiles files successfully validated!" > $checkfile
	rm $tmpfile
    else
	echo "Validation failed for year ${year}!!!" > $checkfile
fi

echo "=================================================================="
echo "            ALL FILES VALIDATED"      
echo "=================================================================="


time_end=$(date +%s)
time_taken=$((time_end - time_start))


echo "Total time taken: ${time_taken} seconds"

source deactivate
exit 0
