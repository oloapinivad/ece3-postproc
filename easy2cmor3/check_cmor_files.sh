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


expname=$1
year=$2
missing=1

if [ $# -lt 2 ]; then
   usage
   exit 1
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

DIRFILE=${CMORDIR}/CMIP6/*/EC-Earth-Consortium/*/*/*/*/*/*/*

# configurator
. ${EASYDIR}/config_and_create_metadata.sh $expname

echo "#---------------------------------------------------#"
echo "#-- Variables from varlist vs. Variables produced --#"
echo "#---------------------------------------------------#"
echo "#------- Experiment $expname ---- Year $year -------#"
echo "#---------------------------------------------------#"

echo "varlist.json is: $VARLIST"
echo "output is: $DIRFILE"

echo "#---------------------------------------------------#"
echo

# this is a clumsy way to achieve it, but it works
# find lines
s0=($(cat $VARLIST | grep -nF ': [' | cut -f 1 -d :))
f0=($(cat $VARLIST | grep -n "]" | cut -f 1 -d :))
totvars=0; totfiles=0

# find categories names and count them
for t in $(seq 0 $((${#s0[@]}-1))) ; do
	categ=$(sed "${s0[$t]},${s0[$t]}!d" $VARLIST | cut -f 2 -d '"')
	fullcateg="$fullcateg $categ"
	ll=$((${f0[$t]}-${s0[$t]}-1))
	nvars="$nvars $ll"
done

if [[ $missing -eq 1 ]] ; then
missingfile=missing_vars_${expname}_${year}
rm -f $missingfile
for t in $(seq 0 $((${#s0[@]}-1))) ; do
	categ=$(sed "${s0[$t]},${s0[$t]}!d" $VARLIST | cut -f 2 -d '"')
	#echo $categ >> ${missingfile}
	for ff in  $( seq ${s0[$t]} ${f0[$t]} ) ; do
	 	#file=$( sed -n ${ff}p $VARLIST | grep -n ","  | cut -f 2 -d '"' )
		file=$( sed -n ${ff}p $VARLIST | grep -vn "]"  | cut -f 2 -d '"' )
		#if [[ ! -z $file ]] && [[ $file != "1:        ]," ]] && [[ $file != $categ ]] &&  [[ $file != "        ]," ]]   ; then
		if [[ ! -z $file ]] && [[ $file != $categ ]] ; then
			ff=$(ls ${CMORDIR}/CMIP6/*/EC-Earth-Consortium/*/*/*/${categ}/${file}/*/*/${file}_${categ}_*.nc 2> /dev/null | wc -l )
			if [[ $ff -ne 1 ]] ; then
				echo "$file $categ is missing!" >> ${missingfile} 
			fi
		fi
	done
	echo "--------------------" >> ${missingfile}
done
fi


fullcateg=($fullcateg)
fullvars=($nvars)


# sum together same categories from different models
newvars=""
newcateg=""
for t1 in $(seq 0 $((${#fullcateg[@]}-1))) ; do
	ll=0
	for t2 in $(seq 0 $((${#fullcateg[@]}-1))) ; do
		if [[ ${fullcateg[$t1]} == ${fullcateg[$t2]} ]] ; then
			ll=$((ll + ${fullvars[$t2]}))
		fi
	done
	check=false
	for kk in $newcateg ; do
                if [[ ${fullcateg[$t1]} == $kk ]] ; then
                        check=true
                fi
        done
	[[ $check == true ]] && continue

	newvars="$newvars $ll"
	newcateg="$newcateg ${fullcateg[$t1]}"
done

# arraying the new values
newcateg=($newcateg)
newvars=($newvars)

# do the loop
for t in $(seq 0 $((${#newcateg[@]}-1))) ; do
	#[[ ${newcateg[$t]} == Oclim ]] && continue
	#[[ ${newcateg[$t]} == Oyr ]] && continue
	categ=${newcateg[$t]}
	nvars=${newvars[$t]}

	nfiles=$(ls $DIRFILE/*_${categ}_* 2> /dev/null | wc -l)

	echo "$categ -> Theory:" $nvars "Actual:" $nfiles

	totvars=$((totvars+nvars))
	totfiles=$((totfiles+nfiles))
done

# estimate total data 
echo
perc=$(bc <<< "scale=2; 100*$totfiles/$totvars")
echo "TOTAL -> Theory:" $totvars "Actual:" $totfiles "i.e. $perc % "

# volume occupied
space=$(du -sh $CMORDIR | cut -f 1)
echo "Total space occupied by one year of exp $expname is: $space"
echo

