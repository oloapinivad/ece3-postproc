#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)

#rough scheme for looping on years, it produces up to 15 jobs for each year so beware

EXP=chis
YEAR1=2014
YEAR2=2014
ATM=0
OCE=0
VEG=0
PREPARE=0
QADKRZ=1
NCTIME=0
CORRECT=0
RESO=T255

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do

	# if no ece2cmor is required, skip	
	if [[ $ATM -eq 0 ]] && [[ $OCE -eq 0 ]] && [[ $VEG -eq 0 ]] && [[ $PREPARE -eq 0 ]]  ; then
		continue
	fi

	# launch the tool for ece2cmor
	./run_1year_ece2cmor3.sh -e $EXP -y $YEAR -r $RESO  \
			 -a $ATM -o $OCE -v $VEG -p $PREPARE -c $CORRECT -q 0 -n 0
done 

# launch it for the quality assurance
if [[ $QADKRZ -eq 1 ]] || [[ $NCTIME -eq 1 ]] ; then
	  ./run_1year_ece2cmor3.sh -e $EXP -y $YEAR -r $RESO  \
                         -a 0 -o 0 -v 0 -p 0 -c 0 -q $QADKRZ -n $NCTIME
fi





