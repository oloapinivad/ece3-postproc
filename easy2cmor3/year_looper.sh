#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)

#rough scheme for looping on years, it produces up to 15 jobs for each year so beware

EXP=ap00
YEAR1=1950
YEAR2=1950
ATM=1
OCE=0
MERGE=0
VALID=0
PREPARE=0
CORRECT=0
RESO=T511

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do
	./submit_year.sh -e $EXP -y $YEAR -j $YEAR1 -r $RESO  \
			 -a $ATM -o $OCE -m $MERGE -v $VALID -p $PREPARE -c $CORRECT
done 





