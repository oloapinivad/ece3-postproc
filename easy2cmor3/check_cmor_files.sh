#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Estimation of the produced output by cmorization, comparing to the original varlist.json

usage()
{
   echo "Usage:"
   echo "       ./check_cmor_files.sh expname year"
   echo
}


verbose=0
oce=1
expname=$1
year=$2

if [ $# -ne 2 ]; then
   usage
   exit 2
fi

#--------config file-----

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

 # load utilities
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# conf file and directories
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# set cmordir
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})

#--------loop on tables -------

for table in CMIP6 PRIMAVERA ; do

if [[ -d ${CMORDIR}/$table ]] ; then
	DIRFILE=${CMORDIR}/$table/*/EC-Earth-Consortium/*/*/*
	echo "Single-month structure..."
else 
	DIRFILE=${CMORDIR}
	echo "Merged structure..."
fi

if [[ $table == CMIP6 ]] ; then
	varlist=$EASYDIR/varlist/varlist-cmip6-stream2.json
elif [[ $table == PRIMAVERA ]] ; then
	varlist=$EASYDIR/varlist/varlist-primavera-stream2.json
fi

echo "----------------------------------------------"
echo "Variables from varlist vs. Variables CMORIZED!"
echo "-------- Table $table ------------------------"
echo "Experiment $expname ------------------ Year $year "
echo "----------------------------------------------"

s0=($(cat $varlist | grep -n ": " | cut -f 1 -d :))
f0=($(cat $varlist | grep -n "]" | cut -f 1 -d :))
totvars=0; totfiles=0

for t in $(seq 0 $((${#s0[@]}-1))) ; do
#for t in 16 ; do
	categ=$(sed "${s0[$t]},${s0[$t]}!d" $varlist | cut -f 2 -d '"')
	if [[ $categ == "Omon" ]] || [[ $categ == "SImon" ]] || [[ $categ == "SIday" ]] || [[ $categ == "Oday" ]] || [[ $categ == "PrimOday" ]] || [[ $categ == "PrimOmon" ]] ; then
		if [[ $oce -eq 0 ]] ; then
			continue 
		fi
	fi

	if [[ -d ${CMORDIR}/$table ]] ; then
		nfiles=$(ls $DIRFILE/$categ/*/*/*/*${year}01* 2> /dev/null | wc -l)
	else
		nfiles=$(ls $DIRFILE/*_${categ}_* 2> /dev/null | wc -l)
	fi

	nvars=$((${f0[$t]}-${s0[$t]}-1))
	echo "$categ -> Theory:" $nvars "Actual:" $nfiles
	if [ $verbose -eq 1 ] ; then
		vars=$(sed "$((${s0[$t]}+1)),$((${f0[$t]}-1))!d" $varlist | cut -f 2 -d '"')
		nn=0; mm=0
		for var in $vars ; do
			if [[ "$table" == CMIP6 ]] ; then
				if [ "${var: -2}" -eq "27" ] 2> /dev/null ; then var=${var::-2} ; fi
				if [ ${var: -2} == 7h ] 2> /dev/null ; then var=${var::-2} ; fi
				if [ ${var: -1} == 4 ] 2> /dev/null ; then var=${var::-1} ; fi
				if [ ${var: -2} == "2d" ] 2> /dev/null ; then var=${var::-2} ; fi
				#echo ${var: -2} 
			fi
			if [[ -d ${CMORDIR}/$table ]] ; then
				check=$(ls $DIRFILE/$categ/*/*/*//*${year}01* 2> /dev/null | grep "/${var}_" | wc -l)
			else
				check=$(ls $DIRFILE/*_${categ}_* 2> /dev/null | grep "/${var}_" | wc -l)
			fi

			if [ $check -eq 0 ] ; then
				echo "$var missing"
				nn=$((nn+1))
			elif [ $check -ge 2 ] ; then
				echo "$var is double"
				mm=$((mm+1))
				
			fi
		done
		echo "Missing are $nn, Double are $mm, Overwritten are $((nvars - nfiles - nn +  mm))"
		echo
	fi		
	totvars=$((totvars+nvars))
	totfiles=$((totfiles+nfiles))
	#sed "${s0s[$t]},${f0s[$t]}!d" $varlist 
done 
echo
perc=$(bc <<< "scale=2; 100*$totfiles/$totvars")
echo "TOTAL -> Theory:" $totvars "Actual:" $totfiles "i.e. $perc % "
done

space=$(du -sh $CMORDIR | cut -f 1)
echo "Total space occupied by one year of exp $expname is: $space"
echo

