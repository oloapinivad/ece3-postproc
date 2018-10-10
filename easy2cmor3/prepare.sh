#!/bin/bash
# by Jon Seddon 12th June 2018
# An example script to show the fixes required to a typical netCDF file
# to get PrePARE to validate it successfully.

set -e

# Script to validate output of ece2cmor3 for a Primavera experiment.
# Uses Jon Seddon's primavera-val python tool.
# a conda "validate" environment including iris has been installed
# Adapted from Kristian Strommen

#Will validate all years between year1 and year2 of experiment with name expname
expname=${expname:-qctr}
year=${year:-1950}
NCORESPREP=1

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

#####################################################################################################

export PATH="$CONDADIR:$PATH"

OUTPUT_DIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
LOGFILE=$LOGFILE/PrePARE_${expname}_${year}.txt
source activate ece2cmor3

CMOR_TABLES=$TABDIR
rm -f $LOGFILE

function check_file {
	INFILE=$1
	echo $INFILE
	PrePARE --table-path $TABDIR --max-processes=$NCORESPREP $1 &> ~/tmp.txt
  	local status=$?
	if [ $status -ne 0 ]; then
		cat ~/tmp.txt >> $LOGFILE
	fi
     	return $status
}

echo "Starting checking $OUTPUT_DIR : " >> $LOGFILE
filelist=`find $OUTPUT_DIR | grep '\.nc$'`
filelist=$(find $OUTPUT_DIR/* ! -name "*Prim*" )
#filelist=$(find $OUTPUT_DIR/* -name "*SImon*" )

nfile=$(find $OUTPUT_DIR/* ! -name "*Prim*" | wc -l )

for ncf in $filelist; do

       #echo $ncf
	check=0
	varjump="siage_SImon sicompstren_SImon siflswdtop_SImon sisali_SImon sispeed_SImon sitemptop_SImon sithick_SImon sithick_SIday ta_Emon wap_6hrPlev zg_Emon"
	for varj in $varjump ; do 
		if grep -q "$varj" <<< "$ncf"; then
			echo "Skipping $varj..."
			check=1
		fi
	done
	
	if [[ $check -eq 1 ]] ; then 
		continue
	fi

      	check_file $ncf 
	if [[ "$?" -eq 0 ]] ; then
                echo "$ncf validated_succesfully..." >> $LOGFILE
        fi

done

nval=$(( $(cat $LOGFILE | wc -l) - 1 ))

echo "Validated $nval / $nfile files!!!" >> $LOGFILE
echo "Finished checking $OUTPUT_DIR : " >> $LOGFILE

source deactivate

