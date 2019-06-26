#!/bin/bash
# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Adapted from Pierre-Antoine Bretonniere and Jon Seddon
# Script to call PrePARE to validate NetCDF successfully.

set -e

#Will validate all years between year1 and year2 of experiment with name expname
expname=${expname:-chis}
year=${year:-1850}

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

#####################################################################################################

# activate conda
export PATH="$CONDADIR:$PATH"

# set path and log files
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
cd $CMORDIR
mkdir -p $INFODIR/${expname}
LOGFILE=$INFODIR/${expname}/PrePARE_${expname}_${year}.txt
rm -f $LOGFILE

# start the environment
source activate ece2cmor3


function check_file {
	INFILE=$1
	echo $INFILE
	tmpfile=${BASETMPDIR}/tmp_${RANDOM}_${year}.txt
	PrePARE --table-path $TABDIR --max-processes=$NCORESPREPARE $1 &> ${tmpfile}
  	local status=$?
	if [ $status -ne 0 ]; then
		echo "ERROR"
		cat ${tmpfile} >> $LOGFILE
		exit
	fi
	rm -f ${tmpfile}
     	return $status
}

#echo "Starting checking $CMORDIR : " >> $LOGFILE
#filelist=$(find $CMORDIR | grep '\.nc$')
filelist=$(find $CMORDIR -name "*.nc" )
nfile=$(find $CMORDIR -name "*.nc" | wc -l )

# remove file from Primavera tables that cannot be validated
#filelist=$(find $CMORDIR/* ! -name "*Prim*" )
#nfile=$(find $CMORDIR/* ! -name "*Prim*" | wc -l )

rm -rf ${BASETMPDIR}/tmp_log_${expname}_${year}.txt
for ncf in $filelist ; do

	check=0
	varjump="wap_6hrPlev zg_6hrPlevPt"
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
                echo "$(basename $ncf) validated_succesfully..." >> ${BASETMPDIR}/tmp_log_${expname}_${year}.txt
        fi

done

nval=$(cat  ${BASETMPDIR}/tmp_log_${expname}_${year}.txt | wc -l )
rm -f ${BASETMPDIR}/tmp_log_${expname}_${year}.txt

echo "... year $year, Succesfully validated $nval / $nfile files!!!" >> $LOGFILE
#echo "Finished checking $CMORDIR : " >> $LOGFILE

conda deactivate

