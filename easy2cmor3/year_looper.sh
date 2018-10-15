#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)

#rough scheme for looping on years, it produces up to 15 jobs for each year so beware

EXP=qctr
YEAR1=1951
YEAR2=2000
ATM=0
OCE=0
MERGE=0
VALID=1
PREPARE=0
CORRECT=0
RESO=T511

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do
	./submit_year.sh -e $EXP -y $YEAR -j $YEAR1 -r $RESO  \
			 -a $ATM -o $OCE -m $MERGE -v $VALID -p $PREPARE -c $CORRECT
done 





