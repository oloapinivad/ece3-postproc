#!/bin/bash
#SBATCH --job-name=validate_det3_1995
#SBATCH -n1
#SBATCH --mem=100GB
#SBATCH --time=02:59:00
#SBATCH --account=IscrC_C2HEClim
#SBATCH --output /marconi_scratch/userexternal/pdavini0/log/cmorize/validate_ifs_det3_1995_%j.out
#SBATCH --error /marconi_scratch/userexternal/pdavini0/log/cmorize/validate_ifs_det3_1995_%j.err
#SBATCH --partition=bdw_usr_prod

set -e

#Script to validate output of ece2cmor3 for a Primavera experiment.
#Uses Jon Seddon's primavera-val python tool.

#Will validate all years between YEAR1 and YEAR2 of experiment with name EXP
EXP=${EXP:-det3}
YEAR1=${YEAR1:-1995}
YEAR2=${YEAR2:-1995}
#YEARS="1956 1957 1971 1974"
#YEARS="1993 2000 2011 2013"

#If 0, will do all months. Otherwise choose a specific month (1-12)
#If 13, will run over full year chunk
MONTHS=13

#Specify location of primavera-val
VALDIR=/marconi_work/IscrB_DIXIT/ecearth3/cmorization/primavera-val/bin

#Specify root location of experiment output (data assumed to be ROOTPATH/Year_$year folders)
ROOTPATH=/marconi_scratch/userexternal/pdavini0/ece3/$EXP/cmorized2

#####################################################################################################

CONDADIR=${WORK}/opt/anaconda2/bin
export PATH="$CONDADIR:$PATH"
export PYTHONPATH=/marconi_work/IscrB_DIXIT/ecearth3/cmorization/primavera-val/
source activate validate
VALIDATE=${VALDIR}/validate_data.py

time_start=$(date +%s)
date_start=$(date)

cd $ROOTPATH

if [ "$MONTHS" = "0" ]; then
    FIRSTMON=1
    LASTMON=12
else
    FIRSTMON=$MONTHS
    LASTMON=$MONTHS
fi

echo "=================================================================="
echo "=================================================================="
echo ""
echo "       VALIDATING CMORIZED IFS OUTPUT OF EXPERIMENT ${EXP}"
echo ""
echo "=================================================================="
echo "=================================================================="

#Looping over years
#for year in $YEARS
for year in $(seq ${YEAR1} ${YEAR2})
do
    echo "=================================================================="
    echo "                      YEAR = ${year}"
    echo "=================================================================="
    
    #Looping over months
    for month in $(seq $FIRSTMON $LASTMON)
    do
        if [[ $month != 13 ]] ; then
		echo "------------------------------------------------------------------"
		echo "                      MONTH = ${month}" 
        	echo "------------------------------------------------------------------"
		checkfile=$ROOTPATH/validate_${year}${month}.txt
		folder=${ROOTPATH}/Year_${year}
		# Create tmp dir
        	tmpdir=${folder}/tmp
        	mkdir -p $tmpdir
        	cd ${tmpdir}
		#Find all files that correspond to the correct year/month and link in this folder
        	find .. -name "*${year}$(printf %02g ${month})*" -exec ln -vs "{}" . ';'  
	else
		folder=${ROOTPATH}/Year_${year}
		cd ${folder}
		checkfile=$ROOTPATH/validate_${year}.txt
	fi

	rm -f $checkfile
	nfiles=$(ls | wc -l)
	echo $(pwd)

        #Validate all the (symbolic link) files
        ${VALIDATE} -l debug .

        cd ${folder}
        if [ "$?" = "0" ]; then
            echo "...successfully validated month!"
	if [ $month == 13 ] ; then
		echo "... Year $year, $nfiles files successfully validated!" > $checkfile
	else 
		echo "... Year $year Month $month, $nfiles files successfully validated!" > $checkfile
	fi
        else
            echo "=================================================================="
            echo "Validation failed for year ${year}, month ${month}"
	    echo "Validation failed for year ${year}!!!" > $checkfile
            exit 1
        fi

        #Remove tmp dir
        if [ -d "${tmpdir}" ]; then
            rm -rf "${tmpdir}"        
        fi
	
	if [[ $MONTH == 13 ]] ; then
		break
	fi

    done
done

                

            
echo "=================================================================="
echo "            ALL FILES SUCCESSFULLY VALIDATED"      
echo "=================================================================="


time_end=$(date +%s)
time_taken=$((time_end - time_start))


echo "Total time taken: ${time_taken} seconds"

source deactivate
exit 0
