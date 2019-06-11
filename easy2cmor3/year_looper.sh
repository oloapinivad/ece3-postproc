#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)

#rough scheme for looping on years, it produces up to 15 jobs for each year so beware

EXP=chis
YEAR1=1850
YEAR2=1850
ATM=1
OCE=1
VEG=0
PREPARE=0
CORRECT=0
RESO=T255

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do
	./run_1year_ece2cmor3.sh -e $EXP -y $YEAR -r $RESO  \
			 -a $ATM -o $OCE -v $VEG -p $PREPARE -c $CORRECT
done 





