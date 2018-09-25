#!/bin/bash
#SBATCH --job-name=validate_det3
#SBATCH -n8
#SBATCH --mem=100GB
#SBATCH --job-name validate_det3
#SBATCH --time=02:59:00
#SBATCH --account=IscrC_C2HEClim
#SBATCH --output /marconi_scratch/userexternal/pdavini0/log/cmorize/validate_ifs_det3_%j.out
#SBATCH --error /marconi_scratch/userexternal/pdavini0/log/cmorize/validate_ifs_det3_%j.err
#SBATCH --partition=bdw_usr_prod

set -e

#Script to validate output of ece2cmor3 for a Primavera experiment.
#Uses Jon Seddon's primavera-val python tool.

#Will validate all years between YEAR1 and YEAR2 of experiment with name EXP
EXP=${EXP:-det3}
YEAR1=${YEAR1:-1955}
YEAR2=${YEAR2:-1955}
ncores=1
#YEARS="1956 1957 1971 1974"
#YEARS="1993 2000 2011 2013"

#If 0, will do all months. Otherwise choose a specific month (1-12)
#If 13, will run over full year chunk
MONTHS=13

#Specify location of primavera-val
VALDIR=/marconi_work/IscrB_DIXIT/ecearth3/cmorization/primavera-val/bin

#Specify root location of experiment output (data assumed to be ROOTPATH/Year_$year folders)
ROOTPATH=/marconi_scratch/userexternal/pdavini0/ece3/$EXP/cmorized

#####################################################################################################

CONDADIR=${WORK}/opt/anaconda2/bin
export PATH="$CONDADIR:$PATH"
export PYTHONPATH=/marconi_work/IscrB_DIXIT/ecearth3/cmorization/primavera-val/
source activate validate
VALIDATE=${VALDIR}/validate_data.py

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

#Looping over years
#for year in $YEARS
for year in $(seq ${YEAR1} ${YEAR2}) ; do
    	echo "=================================================================="
    	echo "                      YEAR = ${year}"
    	echo "=================================================================="
    	checkfile=$ROOTPATH/validate_${year}.txt
	folder=${ROOTPATH}/Year_${year}
	rm -f $checkfile
	
	# Create tmp dir
        tmpdir=${folder}/tmp
        mkdir -p $tmpdir
        cd ${tmpdir}
	
	#Find all files that correspond to the correct year/month and link in this folder
        find .. -name "*${year}*" -exec ln -vs "{}" . ';'  

	nfiles=$(ls | wc -l)

	filenames=$(ls)
	ii=0
	for file in $filenames ; do
		ii=$((ii + 1 ))

        	#Validate all the (symbolic link) files
        	${VALIDATE} -l debug -s $file &
		if [[ $ii == $ncores ]] ; then 
			wait
			ii=0
		fi
	done

        cd ${folder}
        #if [ "$?" = "0" ]; then
	#	echo "... Year $year, $nfiles files successfully validated!" > $checkfile
	#else 
	#		echo "... Year $year Month $month, $nfiles files successfully validated!" > $checkfile
	#	fi
        #else
        #    echo "=================================================================="
        #    echo "Validation failed for year ${year}, month ${month}"
	#    echo "Validation failed for year ${year}!!!" > $checkfile
        #    exit 1
        #fi

        #Remove tmp dir
        if [ -d "${tmpdir}" ]; then
            rm -rf "${tmpdir}"        
        fi
	
	if [[ $MONTH == 13 ]] ; then
		break
	fi

    done

                

            
echo "=================================================================="
echo "            ALL FILES SUCCESSFULLY VALIDATED"      
echo "=================================================================="


time_end=$(date +%s)
time_taken=$((time_end - time_start))


echo "Total time taken: ${time_taken} seconds"

source deactivate
exit 0
