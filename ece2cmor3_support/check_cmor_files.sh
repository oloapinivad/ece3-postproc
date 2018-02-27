#!/bin/bash

exp=qsh0
year=2002
table=CMIP6
DIRFILE=/marconi/home/userexternal/pdavini0/scratch/ece3/$exp/cmorized/Year_$year/$table/CMIP/EC-Earth-Consortium/EC-Earth3-HR/historical/r1i1p1f1
categories=$(ls $DIRFILE)
varlist=/marconi/home/userexternal/pdavini0/ecearth3/ece3-postproc/ece2cmor3_support/varlist/varlist-branch-primavera.json
verbose=0

#for cat in $categories ; do
#	nfiles=$(ls $DIRFILE/$cat/*/*/*/* | wc -l)
#	echo $cat $nfiles
#done

echo "----------------------------------------------"
echo "Variables from varlist vs. Variables CMORIZED!"
echo "Experiment $exp ------------------ Year $year "
echo "----------------------------------------------"

s0=($(cat $varlist | grep -n ": " | cut -f 1 -d :))
f0=($(cat $varlist | grep -n "]" | cut -f 1 -d :))

for t in $(seq 0 $((${#s0[@]}-1))) ; do
#for t in 16 ; do
	categ=$(sed "${s0[$t]},${s0[$t]}!d" $varlist | cut -f 2 -d '"')
	nfiles=$(ls $DIRFILE/$categ/*/*/*/* 2> /dev/null | wc -l)
	nvars=$((${f0[$t]}-${s0[$t]}-1))
	echo "$categ -> Theory:" $nvars "Actual:" $nfiles
	if [ $verbose -eq 1 ] ; then
		vars=$(sed "$((${s0[$t]}+1)),$((${f0[$t]}-1))!d" $varlist | cut -f 2 -d '"')
		nn=0; mm=0
		for var in $vars ; do
			if [ "${var: -2}" -eq "27" ] 2> /dev/null ; then var=${var::-2} ; fi
			if [ ${var: -2} == 7h ] 2> /dev/null ; then var=${var::-2} ; fi
			#echo ${var: -2} 
			check=$(ls $DIRFILE/$categ/*/*/*/* 2> /dev/null | grep "/${var}_" | wc -l)
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
perc=$(bc <<< "scale=2; $totfiles/$totvars*100")
echo "TOTAL -> Theory:" $totvars "Actual:" $totfiles "i.e. $perc % "
space=$(du -sh $DIRFILE | cut -f 1)
echo "Total space occupied by one year of exp $exp is: $space"
echo
